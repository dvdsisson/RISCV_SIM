"""
CNN Training Script for CIFAR-10
=================================
Pipeline:
  1. Convert source images → BMP format  (saved to bmp_cache/)
  2. Read BMP files numerically           (54-byte header + raw RGB pixels)
  3. Train a small CNN in float32         (≤3 conv layers, ≤2 FC layers, ≤16 filters each)
  4. Quantize weights/biases → uint8 and save as hex text files

Architecture:
  Conv1:  3 → 16 filters, 3×3, BN, ReLU
  Conv2: 16 → 16 filters, 3×3, BN, ReLU, MaxPool 2×2, Dropout
  Conv3: 16 → 16 filters, 3×3, BN, ReLU, MaxPool 2×2, Dropout
  Flatten: 16 × 8 × 8 = 1024
  FC1:  1024 → 256, BN, ReLU, Dropout
  FC2:   256 → 10

Requirements:
    pip install torch torchvision numpy Pillow
"""

import time
import struct
import numpy as np
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as transforms
from PIL import Image


# ---------------------------------------------------------------------------
# Hardcode your CIFAR-10 path here, or pass via --data_root
# ---------------------------------------------------------------------------
CIFAR10_PATH = "/mnt/c/Users/Aryan/Documents/SeniorDesign/CIFAR-10-images-master/CIFAR-10-images-master"

CIFAR10_CLASSES = [
    "airplane", "automobile", "bird", "cat", "deer",
    "dog", "frog", "horse", "ship", "truck",
]


def fmt_time(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.0f}s"
    elif seconds < 3600:
        return f"{seconds/60:.1f}m"
    else:
        return f"{seconds/3600:.1f}h"


# ---------------------------------------------------------------------------
# Step 1 & 2: BMP conversion + numerical BMP reader
# ---------------------------------------------------------------------------

def convert_images_to_bmp(src_root: str, bmp_root: str) -> None:
    """
    Walk src_root/{train,test}/<class>/*.png|jpg and re-save every image
    as a 32×32 RGB BMP under bmp_root/{train,test}/<class>/<stem>.bmp.
    Skips files that already exist so re-runs are fast.
    """
    src_root = Path(src_root)
    bmp_root = Path(bmp_root)
    converted = skipped = 0

    for split in ("train", "test"):
        for class_name in CIFAR10_CLASSES:
            src_dir = src_root / split / class_name
            dst_dir = bmp_root / split / class_name
            if not src_dir.exists():
                raise FileNotFoundError(f"Missing source folder: {src_dir}")
            dst_dir.mkdir(parents=True, exist_ok=True)

            for img_path in sorted(src_dir.iterdir()):
                if img_path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".bmp"}:
                    continue
                dst_path = dst_dir / (img_path.stem + ".bmp")
                if dst_path.exists():
                    skipped += 1
                    continue
                img = Image.open(img_path).convert("RGB").resize((32, 32))
                img.save(dst_path, format="BMP")
                converted += 1

    print(f"  BMP conversion: {converted} converted, {skipped} already existed.")


def read_bmp_numerical(bmp_path: str):
    """
    Manually parse a 24-bit BMP file.

    Returns
    -------
    header_bytes : bytes   — the raw 54-byte BMP header
    header_fields: dict    — human-readable header fields
    pixels       : np.ndarray, shape (H, W, 3), dtype uint8, channel order RGB
    """
    with open(bmp_path, "rb") as f:
        raw = f.read()

    # --- BMP header (14 bytes) ---
    signature  = raw[0:2]          # 'BM'
    file_size  = struct.unpack_from("<I", raw,  2)[0]
    reserved   = struct.unpack_from("<I", raw,  6)[0]
    px_offset  = struct.unpack_from("<I", raw, 10)[0]

    # --- DIB header / BITMAPINFOHEADER (40 bytes starting at offset 14) ---
    dib_size   = struct.unpack_from("<I", raw, 14)[0]
    width      = struct.unpack_from("<i", raw, 18)[0]
    height     = struct.unpack_from("<i", raw, 22)[0]   # negative = top-down
    planes     = struct.unpack_from("<H", raw, 26)[0]
    bpp        = struct.unpack_from("<H", raw, 28)[0]
    compression= struct.unpack_from("<I", raw, 30)[0]
    img_size   = struct.unpack_from("<I", raw, 34)[0]
    x_ppm      = struct.unpack_from("<i", raw, 38)[0]
    y_ppm      = struct.unpack_from("<i", raw, 42)[0]
    clr_used   = struct.unpack_from("<I", raw, 46)[0]
    clr_imp    = struct.unpack_from("<I", raw, 50)[0]

    header_bytes = raw[:54]
    header_fields = dict(
        signature=signature, file_size=file_size, reserved=reserved,
        pixel_data_offset=px_offset, dib_header_size=dib_size,
        width=width, height=abs(height), planes=planes,
        bits_per_pixel=bpp, compression=compression,
        image_data_size=img_size, x_pixels_per_meter=x_ppm,
        y_pixels_per_meter=y_ppm, colors_used=clr_used,
        colors_important=clr_imp,
    )

    # --- Pixel data ---
    # BMP rows are bottom-up (unless height is negative) and padded to 4 bytes
    abs_h    = abs(height)
    row_size = (width * 3 + 3) & ~3          # bytes per row incl. padding
    pixels   = np.zeros((abs_h, width, 3), dtype=np.uint8)

    for row_idx in range(abs_h):
        if height > 0:                        # normal: bottom-up storage
            dest_row = abs_h - 1 - row_idx
        else:                                 # top-down storage
            dest_row = row_idx
        offset = px_offset + row_idx * row_size
        for col in range(width):
            b = raw[offset + col * 3]
            g = raw[offset + col * 3 + 1]
            r = raw[offset + col * 3 + 2]
            pixels[dest_row, col] = [r, g, b]   # store as RGB

    return header_bytes, header_fields, pixels


# ---------------------------------------------------------------------------
# Dataset: reads from the BMP cache
# ---------------------------------------------------------------------------

class CIFAR10BMP(Dataset):
    """
    Loads images from the BMP cache produced by convert_images_to_bmp().
    Uses our own BMP reader for correctness, then wraps with standard transforms.
    """
    def __init__(self, bmp_root: str, train: bool = True):
        split     = "train" if train else "test"
        split_dir = Path(bmp_root) / split
        self.samples = []

        for label_idx, class_name in enumerate(CIFAR10_CLASSES):
            class_dir = split_dir / class_name
            if not class_dir.exists():
                raise FileNotFoundError(f"Missing BMP class folder: {class_dir}")
            for img_path in sorted(class_dir.iterdir()):
                if img_path.suffix.lower() == ".bmp":
                    self.samples.append((img_path, label_idx))

        if not self.samples:
            raise RuntimeError(f"No BMP images found under {split_dir}")

        if train:
            self._transform = transforms.Compose([
                transforms.RandomHorizontalFlip(),
                transforms.RandomCrop(32, padding=4),
                transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
                transforms.ToTensor(),
                transforms.Normalize(
                    mean=[0.4914, 0.4822, 0.4465],
                    std= [0.2470, 0.2435, 0.2616],
                ),
            ])
        else:
            self._transform = transforms.Compose([
                transforms.ToTensor(),
                transforms.Normalize(
                    mean=[0.4914, 0.4822, 0.4465],
                    std= [0.2470, 0.2435, 0.2616],
                ),
            ])

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        img_path, label = self.samples[idx]
        # Use our numerical BMP reader → get RGB array → PIL → transform
        _, _, pixels = read_bmp_numerical(str(img_path))   # (32, 32, 3) uint8
        img = Image.fromarray(pixels, mode="RGB")
        return self._transform(img), label


# ---------------------------------------------------------------------------
# Step 3: Model  (≤3 conv layers, ≤16 filters per layer, ≤2 FC layers)
# ---------------------------------------------------------------------------

class SmallCIFAR10CNN(nn.Module):
    """
    3 conv layers × 16 filters, 2 FC layers.
    Input : (N, 3, 32, 32)
    After pool1 : (N, 16, 16, 16)
    After pool2 : (N, 16,  8,  8)
    Flatten     :  16 * 8 * 8 = 1024
    FC1         :  1024 → 256
    FC2         :   256 → 10
    """
    def __init__(self, dropout: float = 0.35):
        super().__init__()

        # --- Conv block 1 ---
        self.conv1 = nn.Conv2d(3,  16, kernel_size=3, padding=1)
        self.bn1   = nn.BatchNorm2d(16)

        # --- Conv block 2 ---
        self.conv2 = nn.Conv2d(16, 16, kernel_size=3, padding=1)
        self.bn2   = nn.BatchNorm2d(16)

        # --- Conv block 3 ---
        self.conv3 = nn.Conv2d(16, 16, kernel_size=3, padding=1)
        self.bn3   = nn.BatchNorm2d(16)

        self.pool    = nn.MaxPool2d(2, 2)
        self.dropout = nn.Dropout(dropout)

        # --- FC layers ---
        self.fc1 = nn.Linear(16 * 8 * 8, 256)
        self.bn4 = nn.BatchNorm1d(256)
        self.fc2 = nn.Linear(256, 10)

    def forward(self, x):
        # Block 1 — no pool (keep spatial size 32×32)
        x = F.relu(self.bn1(self.conv1(x)))
        x = self.dropout(x)

        # Block 2 — pool → 16×16
        x = F.relu(self.bn2(self.conv2(x)))
        x = self.pool(x)
        x = self.dropout(x)

        # Block 3 — pool → 8×8
        x = F.relu(self.bn3(self.conv3(x)))
        x = self.pool(x)
        x = self.dropout(x)

        # FC
        x = x.view(x.size(0), -1)            # 16*8*8 = 1024
        x = F.relu(self.bn4(self.fc1(x)))
        x = self.dropout(x)
        return self.fc2(x)


# ---------------------------------------------------------------------------
# Step 4: Quantise float32 → uint8 and save as hex text
# ---------------------------------------------------------------------------

def quantize_to_uint8(tensor: torch.Tensor) -> np.ndarray:
    """
    Linearly scale float32 tensor into [0, 255] → uint8.
    Stores scale/offset metadata alongside so the values can be dequantized
    if needed: float = (uint8 / 255) * (t_max - t_min) + t_min
    """
    t = tensor.detach().cpu().float()
    t_min, t_max = float(t.min()), float(t.max())
    if t_max == t_min:
        return np.full(t.shape, 128, dtype=np.uint8), t_min, t_max
    scaled = (t - t_min) / (t_max - t_min) * 255.0
    return scaled.round().clamp(0, 255).numpy().astype(np.uint8), t_min, t_max


def save_weights_as_hex(save_dir: str, model: nn.Module) -> None:
    """
    For every conv/fc weight and bias:
      1. Quantize to uint8
      2. Flatten and write one hex byte per line  (e.g. "0x3F\n")
      3. Also write a companion *_meta.txt with shape, dtype, t_min, t_max
    """
    save_dir = Path(save_dir)
    save_dir.mkdir(parents=True, exist_ok=True)

    layer_map = {
        "conv1_weights": model.conv1.weight,
        "conv1_biases":  model.conv1.bias,
        "conv2_weights": model.conv2.weight,
        "conv2_biases":  model.conv2.bias,
        "conv3_weights": model.conv3.weight,
        "conv3_biases":  model.conv3.bias,
        "fc1_weights":   model.fc1.weight,
        "fc1_biases":    model.fc1.bias,
        "fc2_weights":   model.fc2.weight,
        "fc2_biases":    model.fc2.bias,
    }

    print(f"\nQuantizing float32 → uint8 and saving hex to: {save_dir}/")
    for name, param in layer_map.items():
        arr, t_min, t_max = quantize_to_uint8(param)

        # --- Hex file ---
        hex_path = save_dir / f"{name}.hex"
        with open(hex_path, "w") as f:
            for byte_val in arr.flatten():
                f.write(f"0x{byte_val:02X}\n")

        # --- Metadata file ---
        meta_path = save_dir / f"{name}_meta.txt"
        with open(meta_path, "w") as f:
            f.write(f"name      : {name}\n")
            f.write(f"shape     : {list(arr.shape)}\n")
            f.write(f"dtype     : uint8\n")
            f.write(f"num_bytes : {arr.size}\n")
            f.write(f"t_min     : {t_min:.8f}   (float32 value mapped to 0x00)\n")
            f.write(f"t_max     : {t_max:.8f}   (float32 value mapped to 0xFF)\n")
            f.write("dequant   : float = (uint8 / 255) * (t_max - t_min) + t_min\n")

        print(f"  {name:20s}  shape={list(arr.shape)}  → {hex_path.name}  "
              f"({arr.size} bytes)")

    # Also save a single combined .npz for convenience
    npz_data = {}
    for name, param in layer_map.items():
        arr, _, _ = quantize_to_uint8(param)
        npz_data[name] = arr
    np.savez(save_dir / "model_all_layers_uint8.npz", **npz_data)
    print(f"\n  Combined uint8 archive : model_all_layers_uint8.npz")


# ---------------------------------------------------------------------------
# Training loop
# ---------------------------------------------------------------------------

def train(
    epochs: int = 30,
    batch_size: int = 128,
    lr: float = 0.05,
    device_str: str = "cpu",
    data_root: str = CIFAR10_PATH or "./cifar10_data",
    bmp_cache: str = None,
    save_path: str = "/mnt/c/Users/Aryan/Documents/SeniorDesign/model_weights",
    log_every: int = 100,
    demo_bmp: bool = True,
):
    if bmp_cache is None:
        bmp_cache = str(Path(data_root).parent / "cifar10_bmp_cache")

    device = torch.device(device_str)
    print("=" * 60)
    print(f"Device     : {device}")
    print(f"Epochs     : {epochs}")
    print(f"Batch size : {batch_size}")
    print(f"LR         : {lr}")
    print(f"Data root  : {data_root}")
    print(f"BMP cache  : {bmp_cache}")
    print(f"Save path  : {save_path}")
    print("=" * 60)

    # ------------------------------------------------------------------
    # Step 1: Convert all images to BMP
    # ------------------------------------------------------------------
    print("\n[Step 1] Converting images to BMP format...")
    convert_images_to_bmp(data_root, bmp_cache)

    # ------------------------------------------------------------------
    # Step 2: Demonstrate numerical BMP reading on one sample image
    # ------------------------------------------------------------------
    if demo_bmp:
        sample_bmp = next((Path(bmp_cache) / "train" / "airplane").iterdir())
        hdr_bytes, hdr_fields, pixels = read_bmp_numerical(str(sample_bmp))
        print(f"\n[Step 2] BMP numerical demo  →  {sample_bmp.name}")
        print(f"  Header (54 bytes, hex): {hdr_bytes.hex(' ', 1)[:80]}...")
        print(f"  Width: {hdr_fields['width']}  Height: {hdr_fields['height']}  BPP: {hdr_fields['bits_per_pixel']}")
        print(f"  Top-left pixel RGB: {pixels[0, 0].tolist()}")
        print(f"  Pixel array shape: {pixels.shape}  dtype: {pixels.dtype}")

    # ------------------------------------------------------------------
    # Step 3: Build dataset + train
    # ------------------------------------------------------------------
    print("\n[Step 3] Loading BMP dataset...")
    train_set    = CIFAR10BMP(bmp_cache, train=True)
    test_set     = CIFAR10BMP(bmp_cache, train=False)
    train_loader = DataLoader(train_set, batch_size=batch_size, shuffle=True,  num_workers=0)
    test_loader  = DataLoader(test_set,  batch_size=batch_size, shuffle=False, num_workers=0)
    print(f"  {len(train_set):,} train  |  {len(test_set):,} test  |  {len(train_loader)} batches")

    model     = SmallCIFAR10CNN().to(device)
    criterion = nn.CrossEntropyLoss()

    # Warm-up for 5 epochs then cosine annealing
    optimizer = torch.optim.SGD(
        model.parameters(), lr=lr, momentum=0.9, weight_decay=2e-4, nesterov=True
    )
    warmup_epochs = 5
    def lr_lambda(ep):
        if ep < warmup_epochs:
            return (ep + 1) / warmup_epochs
        # cosine decay from 1.0 → 0.0 over remaining epochs
        progress = (ep - warmup_epochs) / max(1, epochs - warmup_epochs)
        return 0.5 * (1.0 + np.cos(np.pi * progress))
    scheduler = torch.optim.lr_scheduler.LambdaLR(optimizer, lr_lambda)

    total_params = sum(p.numel() for p in model.parameters())
    print(f"\nModel: SmallCIFAR10CNN  ({total_params:,} parameters)")
    print(f"  Conv1 :  3 → 16 filters, 3×3, BN, ReLU, Dropout")
    print(f"  Conv2 : 16 → 16 filters, 3×3, BN, ReLU, MaxPool, Dropout")
    print(f"  Conv3 : 16 → 16 filters, 3×3, BN, ReLU, MaxPool, Dropout")
    print(f"  FC1   : 1024 → 256, BN, ReLU, Dropout")
    print(f"  FC2   :  256 → 10")
    print()

    train_start = time.time()

    for epoch in range(1, epochs + 1):
        model.train()
        epoch_start = time.time()
        total_loss  = 0.0
        correct     = 0
        total       = 0
        current_lr  = scheduler.get_last_lr()[0]

        print(f"Epoch {epoch:>2}/{epochs}  (lr={current_lr:.5f})")

        for batch_idx, (imgs, labels) in enumerate(train_loader):
            imgs, labels = imgs.to(device), labels.to(device)
            optimizer.zero_grad()
            logits = model(imgs)
            loss   = criterion(logits, labels)
            loss.backward()
            optimizer.step()

            total_loss += loss.item()
            correct    += (logits.argmax(1) == labels).sum().item()
            total      += labels.size(0)

            if (batch_idx + 1) % log_every == 0 or (batch_idx + 1) == len(train_loader):
                done    = batch_idx + 1
                elapsed = time.time() - epoch_start
                eta     = (elapsed / done) * (len(train_loader) - done)
                print(f"  batch {done:>4}/{len(train_loader)}"
                      f"  loss={loss.item():.4f}"
                      f"  acc={100*correct/total:.1f}%"
                      f"  eta={fmt_time(eta)}")

        scheduler.step()

        # Validation
        train_acc = 100.0 * correct / total
        avg_loss  = total_loss / len(train_loader)

        model.eval()
        val_correct = 0
        val_total   = 0
        with torch.no_grad():
            for imgs, labels in test_loader:
                imgs, labels = imgs.to(device), labels.to(device)
                val_correct += (model(imgs).argmax(1) == labels).sum().item()
                val_total   += labels.size(0)
        val_acc = 100.0 * val_correct / val_total

        epoch_time = time.time() - epoch_start
        elapsed    = time.time() - train_start
        eta_total  = (elapsed / epoch) * (epochs - epoch)

        print(f"\n  ── Epoch {epoch} ────────────────────────────────────────")
        print(f"     Train loss : {avg_loss:.4f}")
        print(f"     Train acc  : {train_acc:.2f}%")
        print(f"     Val acc    : {val_acc:.2f}%  {'✓ ≥80%' if val_acc >= 80 else '…below target'}")
        print(f"     Epoch time : {fmt_time(epoch_time)}")
        if epoch < epochs:
            print(f"     ETA        : {fmt_time(eta_total)} remaining")
        print()

    total_time = time.time() - train_start
    print(f"Training complete in {fmt_time(total_time)}")
    print(f"Final validation accuracy: {val_acc:.2f}%")

    # ------------------------------------------------------------------
    # Step 4: Quantize and save as hex
    # ------------------------------------------------------------------
    print("\n[Step 4] Saving weights/biases as uint8 hex...")
    save_weights_as_hex(save_path, model)
    print("\nDone. All hex weight files are in:", save_path)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="CIFAR-10 CNN — BMP pipeline, trains float32, saves uint8 hex weights"
    )
    parser.add_argument("--epochs",     type=int,   default=30)
    parser.add_argument("--batch_size", type=int,   default=128)
    parser.add_argument("--lr",         type=float, default=0.05)
    parser.add_argument("--device",     type=str,   default="cpu",
                        choices=["cpu", "cuda", "mps"])
    parser.add_argument("--data_root",  type=str,   default=CIFAR10_PATH or "./cifar10_data",
                        help="Folder containing train/ and test/ subfolders")
    parser.add_argument("--bmp_cache",  type=str,   default=None,
                        help="Where to store converted BMP files (default: sibling of data_root)")
    parser.add_argument("--save_path",  type=str,
                        default="/mnt/c/Users/Aryan/Documents/SeniorDesign/model_weights")
    parser.add_argument("--log_every",  type=int,   default=100)
    parser.add_argument("--no_demo",    action="store_true",
                        help="Skip the BMP numerical demo printout")
    args = parser.parse_args()

    train(
        epochs=args.epochs,
        batch_size=args.batch_size,
        lr=args.lr,
        device_str=args.device,
        data_root=args.data_root,
        bmp_cache=args.bmp_cache,
        save_path=args.save_path,
        log_every=args.log_every,
        demo_bmp=not args.no_demo,
    )