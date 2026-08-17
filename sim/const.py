def h(x, w=8):
    return '0x%0*X' % (w, x & ((1 << (4*w))-1))
a, b = 0x12345678, 0x9abcdef0
print("mul_lo :", h((a*b) & 0xffffffff))
print("mul_hiU:", h((a*b) >> 32))
sb = b - 0x100000000
print("mulh_s :", h((a*sb) >> 32))
c, d = 0x30000000, 0x90000000
print("mulhsu :", h((c*d) >> 32))
q = 0xABCD1234 // 0x1234
r = 0xABCD1234 % 0x1234
print("divu_q :", h(q))
print("divu_r :", h(r))
print("sq32   :", h((0x30000000 * 0x30000000) >> 32))
