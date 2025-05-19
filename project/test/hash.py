from werkzeug.security import generate_password_hash

hash = generate_password_hash("D0tt0dr1v3r*")
print(hash)