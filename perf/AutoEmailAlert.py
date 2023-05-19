import os
import socket
import yagmail
import argparse
from Crypto.Cipher import AES

import warnings
warnings.filterwarnings("ignore")

def inform(res, content, email, password = None):
    if password is None:
        password = os.environ.get('EMAIL_PASSWORD')

    hostname = socket.gethostbyname_ex(socket.gethostname())[0]
    index = hostname + "$" + os.path.basename(os.path.abspath(os.path.dirname(os.getcwd())))
    indexpath = os.getcwd()
    
    if res == 0:
        subject = f"OK: {index}"
        contents = f"{hostname} 服务器中程序执行完毕，执行目录 {indexpath}"
    elif res == "0":
        subject = f"SUCC: {index}"
        contents =  f"{hostname} 服务器中程序执行成功，执行目录 {indexpath}"
    else:
        subject = f"FAIL: {index}"
        contents =  f"{hostname} 服务器中程序执行出错，执行目录 {indexpath}"
    
    if content != "":
        subject += f"{content}"
        contents += "\n" + content

    yag = yagmail.SMTP(user=email, host="smtp.qq.com", password=password)
    yag.send(email, subject, contents)
    yag.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Auto Email Alert Arguments")
    parser.add_argument('--res', '-r', help="excute result for email contents", default=0)
    parser.add_argument('--email', '-e', help="email address", default="maxpicca@qq.com")
    parser.add_argument('--content', '--txt', help="email content", default="")
    args = parser.parse_args()

    inform(args.res, args.content, args.email)