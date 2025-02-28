import os
from django.db import models
from cryptography.fernet import Fernet
from argon2 import low_level
from base64 import urlsafe_b64encode

class KeyPart1(models.Model):
    key = models.CharField(max_length=100)

class KeyPart2(models.Model):
    key = models.CharField(max_length=100)

class Information(models.Model):
    id = models.AutoField(primary_key=True)
    owner = models.ForeignKey('auth.User', on_delete=models.CASCADE)
    userName = models.CharField(max_length=200)
    password = models.CharField(max_length=200)
    website = models.URLField()
    key1 = models.ForeignKey(KeyPart1, on_delete=models.CASCADE)
    key2 = models.ForeignKey(KeyPart2, on_delete=models.CASCADE)
    salt = models.BinaryField(max_length=16)

    def save(self, client_password=None, *args, **kwargs):
        self.salt = os.urandom(16)  # generate a random salt
        argon2Key = low_level.hash_secret_raw(
            secret=client_password.encode(),
            salt=self.salt,
            time_cost=3,
            memory_cost=65536,
            parallelism=4,
            hash_len=32,
            type=low_level.Type.ID)
        fernetRndmKey = Fernet.generate_key()
        fernetArgObj = Fernet(urlsafe_b64encode(argon2Key))
        encryptedKey = fernetArgObj.encrypt(fernetRndmKey)
        if not self.key1_id or not self.key2_id:
            part1 = KeyPart1.objects.create(key=encryptedKey[:72].decode())
            part2 = KeyPart2.objects.create(key=encryptedKey[72:].decode())
            self.key1 = part1
            self.key2 = part2
        else:
            self.key1.key = encryptedKey[:72].decode()
            self.key1.save()
            self.key2.key = encryptedKey[72:].decode()
            self.key2.save()
        fernetObj = Fernet(fernetRndmKey)
        self.userName = fernetObj.encrypt(self.userName.encode()).decode()
        self.password = fernetObj.encrypt(self.password.encode()).decode()
        self.website = fernetObj.encrypt(self.website.encode()).decode()
        super().save(*args, **kwargs)
    
    @classmethod
    def get_information(cls, id=None, user=None, client_password=None):
        if user:
            infos = cls.objects.filter(owner=user)
        else:
            infos = cls.objects.none()

        if id:
            try:
                info = cls.objects.get(id=id)
                argon2Key = low_level.hash_secret_raw(
                    secret=client_password.encode(),
                    salt=info.salt,
                    time_cost=3,
                    memory_cost=65536,
                    parallelism=4,
                    hash_len=32,
                    type=low_level.Type.ID)
                fernetKeyEncrypted = (info.key1.key + info.key2.key).encode()
                fernetArgonObj = Fernet(urlsafe_b64encode(argon2Key))
                fernetKeyDecrypted = fernetArgonObj.decrypt(fernetKeyEncrypted)
                fernetObj = Fernet(fernetKeyDecrypted)
                info.userName = fernetObj.decrypt(info.userName.encode()).decode()
                info.password = fernetObj.decrypt(info.password.encode()).decode()
                info.website = fernetObj.decrypt(info.website.encode()).decode()
                return info
            except Information.DoesNotExist:
                print(f"Information with id {id} does not exist.")
        else:
            for info in infos:
                argon2Key = low_level.hash_secret_raw(
                    secret=client_password.encode(),
                    salt=info.salt,
                    time_cost=3,
                    memory_cost=65536,
                    parallelism=4,
                    hash_len=32,
                    type=low_level.Type.ID)
                fernetKeyEncrypted = (info.key1.key + info.key2.key).encode()
                fernetArgonObj = Fernet(urlsafe_b64encode(argon2Key))
                print(f'fernet key derrieved after saving: {fernetArgonObj}')
                fernetKeyDecrypted = fernetArgonObj.decrypt(fernetKeyEncrypted)
                fernetObj = Fernet(fernetKeyDecrypted)
                info.userName = fernetObj.decrypt(info.userName.encode()).decode()
                info.password = fernetObj.decrypt(info.password.encode()).decode()
                info.website = fernetObj.decrypt(info.website.encode()).decode()
            return infos