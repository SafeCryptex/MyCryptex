"""
 This script has been tested under Python 3.13 and is expected to work correctly with that version.
 To use this script, simply place the encrypted file with the same name in the same directory,
 and then run the script to decrypt it.
 
 Note: This script relies on two external libraries, 'AES' from the PyCrypto library and 'argon2'.
 These libraries may need to be installed if they are not already present in your Python environment.
 You can install these libraries using pip, the Python package manager, with the following commands:
 - For PyCrypto (which includes AES): `pip install pycryptodome`
 - For argon2: `pip install argon2-cffi`
 
 """

import os
import base64
import binascii
from Crypto.Cipher import AES
from argon2 import PasswordHasher, Type


def RemoveAESPadding(Str):
    """
    This function removes the padding added by AES encryption according to the PKCS7-like padding scheme.

    Args:
        Str (bytes): The bytes object which may contain padding.

    Returns:
        bytes: The bytes object with padding removed.
    """
    length = len(Str)
    PadLen = Str[length - 1]

    if PadLen <= 16:
        IsPadding = True
        for i in range(length - PadLen, length - 1):
            if Str[i]!= PadLen:
                IsPadding = False
                break

        if IsPadding:
            Str = Str[:length - PadLen]

    return Str


def read_file_and_decrypt():
    """
    This function is used to read an encrypted file and decrypt it.
    It first gets the path of the file with the same name as the current py file (without the.py extension) in the current directory.
    Then it reads the file, validates the file header, extracts various metadata like version, password check flag, encryption grade, etc.
    It also gets the password from the user, computes the hash value based on the password and salt, decrypts the encrypted data using AES cipher,
    and finally validates the decryption or writes the decrypted data to a new file depending on the file extension and password check flag.
    """
    # Get the directory where the current py file is located and construct the file path of the file with the same name (without the.py extension)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    file_name_without_extension = os.path.splitext(os.path.basename(__file__))[0]
    file_path = os.path.join(current_dir, file_name_without_extension)

    try:
        with open(file_path, 'rb') as file:
            data = file.read()

        # Convert the string "MyCryptex" to byte stream
        expected_program_name_bytes = "MyCryptex".encode('utf-8')

        # Compare the byte stream of the file header
        if data[:9]!= expected_program_name_bytes:
            print("Invalid file, exiting program.")
            return

        # Read the version number and convert it to an integer
        version_hex = data[9:13]
        version = int(version_hex, 16)

        # Read the no_password_check value and convert it to an integer
        no_password_check_hex = data[13:17]
        no_password_check = int(no_password_check_hex, 16)

        # Read the encryption grade and convert it to an integer
        encryption_grade_hex = data[17:21]
        encryption_grade = int(encryption_grade_hex, 16)

        # Read the length of the salt and convert it to an integer
        salt_length_hex = data[21:25]
        salt_length = int(salt_length_hex, 16)

        # Read the salt value and decode it using base64
        salt = base64.b64decode(data[25:25 + salt_length])

        # Read the length of the hint and convert it to an integer
        hint_length_hex = data[25 + salt_length:25 + salt_length + 4]
        hint_length = int(hint_length_hex, 16)

        # Read the hint value and decode it using base64
        hint = base64.b64decode(data[29 + salt_length:29 + salt_length + hint_length])
        print('Password hint:'+ hint.decode('utf-8') + '\n')

        password = input("Please enter the decryption password: ")
        print('\n')

        # Set the PasswordHasher parameters according to the value of encryption_grade
        if encryption_grade == 0:
            AIterations = 2
            AMemory = 15
            AParallelism = 4
        elif encryption_grade == 2:
            AIterations = 5
            AMemory = 18
            AParallelism = 3
        elif encryption_grade == 3:
            AIterations = 10
            AMemory = 20
            AParallelism = 1
        else:
            AIterations = 3
            AMemory = 16
            AParallelism = 4

        ph = PasswordHasher(
            hash_len=48,  # OutputLength
            type=Type.ID,
            salt_len=len(salt),
            memory_cost=2 ** AMemory,  # Memory
            time_cost=AIterations,  # Iterations
            parallelism=AParallelism  # Parallelism
        )

        # Calculate the HASH value using the argon2id algorithm of the argon2-cffi library
        hash_value = ph.hash(password, salt=salt)

        # Decode the hash value
        decoded_hash = base64.b64decode(hash_value.split('$')[-1])

        # Convert the bytes to HEX
        hash_value = binascii.hexlify(decoded_hash).decode('utf-8')

        key = hash_value[:64]
        iv = hash_value[64:96]

        cipher = AES.new(binascii.unhexlify(key), AES.MODE_CBC, binascii.unhexlify(iv))

        encrypted_data = data[29 + salt_length + hint_length:]
        decrypted_data = cipher.decrypt(encrypted_data)

        file_extension = os.path.splitext(file_path)[1]
        if file_extension == '.cptx':
            if no_password_check == 0:
                # Validate the HASH value
                hash_value_utf8 = hash_value.encode('utf-8')
                if hash_value_utf8.upper() == decrypted_data[:96].upper():
                    plaintext_content = decrypted_data[96:]
                    plaintext_content_without_padding = RemoveAESPadding(plaintext_content)
                    print("Hash validation successful, decryption successful, plaintext content:\n\n", plaintext_content_without_padding.decode('utf-8'))
                else:
                    print("Wrong password, please try again.")
            else:
                plaintext_content = decrypted_data
                plaintext_content_without_padding = RemoveAESPadding(plaintext_content)
                print("Decryption done (skipped password check, please verify content by yourself), plaintext content:\n\n", plaintext_content_without_padding.decode('utf-8'))
        elif file_extension == '.cptf':
            if no_password_check == 0:
                # Validate the HASH value
                hash_value_utf8 = hash_value.encode('utf-8')
                if hash_value_utf8.upper() == decrypted_data[:96].upper():
                    output_file_path = os.path.splitext(file_path)[0]
                    counter = 0
                    file_name, file_extension = os.path.splitext(output_file_path)
                    while True:
                        if counter == 0:
                            file_name_to_write = output_file_path
                        else:
                            file_name_to_write = f"{file_name}({counter}){file_extension}"
                        if not os.path.exists(file_name_to_write):
                            with open(file_name_to_write, 'wb') as output_file:
                                plaintext_content = decrypted_data[96:]
                                plaintext_content_without_padding = RemoveAESPadding(plaintext_content)
                                if output_file.write(plaintext_content_without_padding):
                                    print("Decryption successful, the file has been saved as: ", file_name_to_write)
                            break
                        counter += 1
                else:
                    print("Wrong password, please try again.")
            else:
                output_file_path = os.path.splitext(file_path)[0]
                counter = 0
                file_name, file_extension = os.path.splitext(output_file_path)
                while True:
                    if counter == 0:
                        file_name_to_write = output_file_path
                    else:
                        file_name_to_write = f"{file_name}({counter}){file_extension}"
                    if not os.path.exists(file_name_to_write):
                        with open(file_name_to_write, 'wb') as output_file:
                            plaintext_content = decrypted_data
                            plaintext_content_without_padding = RemoveAESPadding(plaintext_content)
                            if output_file.write(plaintext_content_without_padding):
                                print("Decryption done (skipped password check, please verify content by yourself)! The decrypted file has been saved as: ", file_name_to_write)
                        break
                    counter += 1

    except Exception as e:
        print(f"An error occurred: {e}")
        exit(1)
        
if __name__ == "__main__":
    read_file_and_decrypt()
