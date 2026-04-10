ADDI x1, x1, 160
SLLI x1, x1, 8 #1000
ADDI x2, x1, 0 #1000
SLLI x1, x3, 1 #2000

SLLI x4, x3, 1  #4000
ADD x5, x1, x4 #5000
CONV x3, x4, x5