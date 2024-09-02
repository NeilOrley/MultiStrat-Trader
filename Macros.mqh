//+------------------------------------------------------------------+
//|                                                       Macros.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

// Useful macros for array operations
#ifndef __MACROS_INCLUDE__
#define APPEND(A, V)    A[ArrayResize(A, ArraySize(A) + 1) - 1] = V;
#define FIND(A, V, I)   { for(I=ArraySize(A)-1;I>=0;I--) { if(A[I]==V) break; } }
#define ADD(A, V)       { int i; FIND(A, V, i) if(i==-1) { APPEND(A, V) } }
#define FOREACH(A, D)   { for(int i=0, im=ArraySize(A);i<im;i++) {D;} }
#define REMOVE_AT(A, I) { int s=ArraySize(A);for(int i=I;i<s-1;i++) { A[i]=A[i+1]; } ArrayResize(A, s-1);}
#define REMOVE(A, V)    { int i; FIND(A, V, i) if(i>=0) REMOVE_AT(A, i) }
#define __MACROS_INCLUDE__
#endif
//+------------------------------------------------------------------+
