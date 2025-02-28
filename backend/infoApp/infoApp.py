import string
import secrets
import random
from cryptography.fernet import Fernet
# import os
# import argon2
# from .hashCheck import generateHash


# hashTxtPath = os.path.join(os.path.dirname(os.path.relpath(__file__)), 'hash.txt')
# dbTxtPath = os.path.join(os.path.dirname(os.path.relpath(__file__)), 'db.txt')
# db1TxtPath = os.path.join(os.path.dirname(os.path.relpath(__file__)), 'db1.txt')
# db2TxtPath = os.path.join(os.path.dirname(os.path.relpath(__file__)), 'db2.txt')
   

def generateRandomPassword():
    psswLength = random.randint(16, 30)
    pssw = "".join((secrets.choice(string.ascii_letters + string.digits + string.punctuation) for i in range(psswLength)))
    return pssw

    
# def initialization():
#     loginPssw = checkMasterPassword()
#     if loginPssw != "failed":
#         command = input("Select one of options below:\n1.Generate Random Password and store it\n2.Get Password\n3.Exit\nTell me what to do: ")
#         if command == str(1):
#             storeKey()
#         elif command == str(2):
#             getPassword()    
#         elif command == str(3):
#             exit()
#         else:
#             print("You typed in something strange, Please try again: ")
#             initialization()
#     else:
#         print("Your password was incorrect, Please think twice and try again: ")
#         initialization()