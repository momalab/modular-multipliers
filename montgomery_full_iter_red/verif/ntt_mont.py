import sympy
import random
import math

#--------------------Global variables---------------------------
DWIDTH  = 32
POLYDEG = 256
#Find a prime number P = const_mul * (2**log2POLYDEG) + 1
log2polydeg = int(math.log(POLYDEG, 2))
#const_mul = 3 # for 4096
const_mul = 1 # for 256
#const_mul = 24 # for 512
nroot     = 1 # Exit after finding nroot
modulus = 0xffffffff#const_mul * 2**log2polydeg + 1
R = int(math.log2(modulus))+1
R = 2**DWIDTH #2**R
R_red = R % modulus
R_sqr = R**2 % modulus
R_13 = R**13 % modulus
w = 16#DWIDTH/2
print("w = ", w)
L = math.ceil(DWIDTH/w)
print("R = 2**Lw",2**(L*w))

def gcdExtended(a1, b1):
   #print("a1 = %d, b1 = %d",a1, b1)
   if(a1 == 0):
       p = 0
       q = 1
       gcd = b1
       #print("p = %d, q = %d",p, q);
       return p, q, gcd
   else :
       p1, q1, gcd = gcdExtended(b1%a1, a1)
       #print("p1 = %d, q1 = %d",p1, q1)
       #print("a1 = %d, b1 = %d",a1, b1)
       p = q1 - (b1//a1)*p1
       q = p1
       #print("p = %d, q = %d",p, q)
       return p, q, gcd

def modInverse_fast(a, m):
    x1, y1, g = gcdExtended(a, m)
    if (g != 1):
        #print("Inverse doesn't exist");
        return 1
    else :
        res = (x1 % m + m) % m
        #print("Modular multiplicative inverse is ", res);
        return res

def modInverse(a, m) :
    a = a % m
    for x in range(1, m) :
        if ((a * x) % m == 1) :
            return x
    return 1

def mont_precalc(a, m):
    m_inv = modInverse_fast(a, m)
    return int((m_inv*(2**w) - 1) / m)

def montMul(a, b, m, R_inv):
    out = a*b
    out = out*R_inv
    out = out % m
    return out

def montMul_full(a, b, m, m_inv):
    print("a = ",hex(a))
    print("b = ",hex(b))
    print("m = ",hex(m))
    C   = a*b
    T1  = C
    print("T1 = ",hex(T1))
    for i in range(L):
       T2  = T1 % (2**w)
       T3  = (T2*m_inv) % (2**w)
       T1  = int((T1 + (T3*m))/(2**w))
       print("T1 = ",hex(T1))
       print("T2 = ",hex(T2))
       print("T3 = ",hex(T3))
       print("T3*m = ",hex(T3*m))
    T4  = T1 - m
    if(T4 < 0):
         res = T1
    else:
         res = T4
    return res

def montMul_ntt_friendly(a, b, m, R_inv):
    q = 11111
    w = 7
    K = 7		
    mu = mont_precalc(q, 2**w)
    L = 2
    out = a*b
    T1 = out
    for i in range(L):
        #print("L = ", i)
        T2 = T1 % (2**w)
        T3 = (T2*mu) % (2**w)
        T1 = int((T1 + (T3*q)) / (2**w))
    T4 = T1 - q
    if(T4<0):
         res = T1
    else:
         res = T4	
    return res
    
    
def bitReverse(num, len):
        """
        integer bit reverse
        input: num, bit length
        output: rev_num
        example: input 6(110) output 3(011)
        complexity: O(len)
        """
        rev_num = 0
        for i in range(0, len):
            if (num >> i) & 1:
                rev_num |= 1 << (len - 1 - i)
        return rev_num

def orderReverse(poly, N_bit):
      """docstring for order"""
      for i, coeff in enumerate(poly):
          rev_i = bitReverse(i, N_bit)
          if rev_i > i:
              coeff ^= poly[rev_i]
              poly[rev_i] ^= coeff
              coeff ^= poly[rev_i]
              poly[i] = coeff
      return poly


def ntt(poly, M, N, w, R_inv):
      """number theoretic transform algorithm"""
      N_bit = N.bit_length() - 1
      print ("poly:", poly)
      rev_poly = orderReverse(poly, N_bit)
      print ("rev_poly:", poly)
      for i in range(0, N_bit):
          points1, points2 = [], []
          for j in range(0, int(N / 2)):
              shift_bits = N_bit - 1 - i
              P = (j >> shift_bits) << shift_bits
              w_P = w ** P % M
              even = poly[2 * j]
              #odd = poly[2 * j + 1] * w_P
              w_P = (w_P*R) % M
              odd = montMul(poly[2 * j + 1], w_P, M, R_inv)
              print("Stage :", i, "npoint :", j, "even :", poly[2 * j], "odd :", poly[2 * j + 1], "twiddle :", w_P, "Result :", (even + odd) % M,  (even - odd) % M )
              points1.append((even + odd) % M)
              points2.append((even - odd) % M)
              # TODO: use barrett modular reduction
              points = points1 + points2
          if i != N_bit:
              poly = points
      return points



def gcd(a,b):
    while b != 0:
        a, b = b, a % b
    return a

#def primRoots(modulo):
#    roots = []
#    required_set = set(num for num in range (1, modulo) if gcd(num, modulo) == 1)
#
#    for g in range(1, modulo):
#        actual_set = set(pow(g, powers) % modulo for powers in range (1, modulo))
#        if required_set == actual_set:
#            roots.append(g)
#    return roots

def primRoots(modulo, cmul, nroots):
  roots = []
  hit   = 0
  for g in range(1, modulo) :
    if (hit == nroots) :
      break
    else :
      for powers in range (1, modulo) :
        pow_mod = pow(g, powers) % modulo
        if (pow_mod == 1) :
          if (powers == modulo-1) :
            if (pow(g, cmul) < modulo) :
              roots.append(pow(g, cmul))
              hit = hit + 1
          else :
            break
  return roots


m_inv = mont_precalc((2**w)%modulus, modulus)
R_inv = modInverse_fast(R_red, modulus)
invpolydeg = modInverse_fast(POLYDEG, modulus)
invpolydeg2 = modInverse_fast(POLYDEG, modulus)
print("Mod Inverse fast : ", invpolydeg, " and mod Inverse fast ", invpolydeg2)
invpolydeg = modInverse_fast(POLYDEG, modulus)
invpolydeg2 = modInverse_fast(POLYDEG, modulus)
print("Mod Inverse ", invpolydeg, " and mod Inverse : ", invpolydeg2)
print("-----Modulus, Nth Root of Unity and Selected Nth root of unity-----------")
print("Modulus :", modulus)
print("m_inv :", m_inv)
print("R:", R)
print("R_red:", R_red)
print("R_inv:", R_inv)
print("R_sqr:", R_sqr)
print("R_13:", R_13)
#primitive_roots = primRoots(modulus, const_mul, nroot)
#print("Primitive root of unity :", primitive_roots)
#nth_rou = primitive_roots[0]
#print("Selected Nth Root of Unity", nth_rou)
print("--------------------------------------------------------------------------")
check1 = montMul(modulus-1, modulus-3, modulus, R_inv)
print("check1 = ", check1)
check2 = montMul_ntt_friendly(modulus-1, modulus-3, modulus, R_inv)
print("check2 = ", check2)
check3 = montMul_full(modulus-1, modulus-3, modulus, m_inv)
print("check3 = ", check3)

##--------------------------------------------------------------
#
##--------------------Root of Unity---------------------------
##Find a prime number P = c * (2**k) + 1
#lst = list(range(modulus-1))
#seq = random.sample(lst, POLYDEG)
##--------------------------------------------------------------
#
##--------------------NTT Input---------------------------
#lst = list(range(modulus-1))
#seq = random.sample(lst, POLYDEG)
##print ("NTT input : ", seq)
##--------------------------------------------------------------
#
#file_ntt = open("./testcases/ntt_mont.v", "w")
#file_ntt.write ("uartm_write_128     (.addr(GPCFG_N_ADDR[0]),        .data(" + str(DWIDTH) + "'d"  + str(modulus) + ")); \n")
#
#for i in range(POLYDEG):
#  file_ntt.write ("coef[" + str(i) + "] = " + str(DWIDTH) + "'d" + str(seq[i]) + ";\n")
#
#for i in range(POLYDEG):
#  file_ntt.write ("twdl[" + str(i) + "] = " + str(DWIDTH) + "'d" + str((R*(nth_rou**i))%modulus) + ";\n")
#
#file_ntt.write ("for (i = 0; i < POLYDEG; i++) begin\n")
#file_ntt.write ("  uartm_write_128     (.addr(FHEMEM0_BASE + 16*i),  .data(coef[i]));\n")
#file_ntt.write ("end\n")
#
#file_ntt.write ("for (i = 0; i < POLYDEG; i++) begin\n")
#file_ntt.write ("  uartm_write_128     (.addr(FHEMEM2_BASE + 16*i),  .data(twdl[i]));\n")
#file_ntt.write ("end\n")
#
## ntt
##expctd_res = sympy.ntt(seq, modulus)
##ntt_output   = ntt(seq, modulus, POLYDEG, nth_rou, R_inv)
###print ("NTT : ", transform)
##for i in range(POLYDEG):
##  j = bitReverse(i, log2polydeg)
##  file_ntt.write ("fhe_exp_res[" + str(i) + "] = " + str(DWIDTH) + "'d" + str(ntt_output[j]) + ";\n")
##
##
##file_ntt.write ("uartm_write         (.addr(GPCFG_FHECTL2),       .data({FHEMEM3_BASE[31:24], FHEMEM2_BASE[31:24], FHEMEM0_BASE[31:24], FHEMEM0_BASE[31:24]}));\n")
##file_ntt.write ("uartm_write         (.addr(GPCFG_FHECTLP_ADDR),  .data(32'b1));\n")
##file_ntt.close()
##
##
##print("-----Checking the correctness of nth root of unity-----------")
#
##check = ntt_output[0]
##print("check = ", check)
##for i in range(POLYDEG):
##	ntt_output[i] = montMul(ntt_output[i], R_13, modulus, R_inv)
##for i in range(20):
##	check = (check*R_red) % modulus
##	print("i, check = ", i, check)
##if (ntt_output == expctd_res) :
##	#print("NTT CHECK PASSED : ", ntt_output)
##	print("CHECK PASSED : ")
##else:
##	print("CHECK FAILED : ", ntt_output)
##	for i in range(POLYDEG):
##		print("i, ntt_output, exp_res: ", i, ntt_output[i], expctd_res[i])
##
##try :
##  if (ntt_output == expctd_res) :
##     #print("NTT CHECK PASSED : ", ntt_output)
##     print("CHECK PASSED : ")
##except :
##  print("CHECK FAILED : ", ntt_output)
##print("--------------------------------------------------------------------------")
##sympy.rootof(x**POLYDEG - 1, i) for i in range(POLYDEG)
##itransform = sympy.intt(transform, modulus)
##print ("INTT : ", itransform)
