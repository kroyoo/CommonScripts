# js

格式转换

```bash
dos2unix filename
such:
dos2unix backup.sh
```

* backup.sh: 来自[秋水逸冰](https://teddysun.com/469.html)的脚本，修改添加同步多个rclone，删除rclone创建目录。

```
 URL: https://git.io/backup.sh
 #加密解密命令
 openssl enc -aes256 -in [DECRYPTED BACKUP] -out "ENCRYPTED.enc" -pass pass:[BACKUPPASS] -md sha1
 openssl enc -aes256 -in [ENCRYPTED BACKUP] -out decrypted_backup.tgz -pass pass:[BACKUPPASS] -d -md sha1
 
 such as:
 openssl enc -aes256 -in "HelloWorld.tar.gz" -out "encrypted.tar.gz.enc" -pass pass:"HelloWorld" -md sha1

 openssl enc -aes256 -in "encrypted.tar.gz.enc" -out decrypted_backup.tar.gz -pass pass:"HelloWorld" -d -md sha1
 
```

* gitfiti.sh: 愉快玩耍github。
* gclone-mount.sh: gclone自动挂载服务脚本

```
# 使用方法
bash <(curl -sL https://git.io/gclone-mount)
```


* stop_by_keyword.sh: kill by keyword
