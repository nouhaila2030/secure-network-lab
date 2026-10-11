# GRUB password and root account lock

## GRUB password (PBKDF2)

1. Generate a hash (you will be asked for the password twice):

```
grub-mkpasswd-pbkdf2
```

2. Add the superuser and the hash to `/etc/grub.d/40_custom`:

```
set superusers="root"
password_pbkdf2 root <PBKDF2_HASH_FROM_STEP_1>
```

3. Regenerate the configuration:

```
sudo update-grub
```

The hash is intentionally not included in this repository. Never publish a real hash: it can be attacked offline.

## Root account lock

```
sudo passwd -l root
```

Administration is done with `sudo` from a named account.
