`timescale 1ns / 1ps

module comparatorblock(
    input greater,
    input less,
    input equal,
    input A,
    input B,
    output nextgreater,
    output nextless,
    output nextequal
    );
wire notA, notB, xorAB, greaterintermediate, lessintermediate, equalintermediate;

not(notA, A);
not(notB, B);
xor(xorAB, A, B);

and(greaterintermediate, equal, A, notB);
or(nextgreater, greater, greaterintermediate);
and(lessintermediate, equal, notA, B);
or(nextless, less, lessintermediate);
not(equalintermediate, xorAB);
and(nextequal, equal, equalintermediate);

endmodule
