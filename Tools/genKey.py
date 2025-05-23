from Crypto import Random
from Crypto.PublicKey import RSA
 
# 伪随机数生成器
random_generator = Random.new().read
# rsa算法生成实例
rsa = RSA.generate(1024, random_generator)
# 私钥的生成
private_pem = rsa.exportKey()
with open("./Server/keys/private.pem", "wb") as f:
    f.write(private_pem)
# 公钥的生成
public_pem = rsa.publickey().exportKey()
with open("./Client/assets/keys/public.pem", "wb") as f:
    f.write(public_pem)
with open("./Server/keys/public.pem", "wb") as f:
    f.write(public_pem)
with open("./Web/public/keys/public.pem", "wb") as f:
    f.write(public_pem)