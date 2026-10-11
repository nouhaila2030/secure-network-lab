# Password policy and account lockout (Ubuntu 24.04 lab)

## Password ageing: /etc/login.defs

```
PASS_MAX_DAYS   90
PASS_MIN_DAYS   7
PASS_WARN_AGE   14
```

## Password complexity: /etc/security/pwquality.conf

Package: `sudo apt install libpam-pwquality -y`

```
minlen = 12
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
```

Each `credit = -1` requires at least one digit, uppercase letter, lowercase letter and special character.

## Lockout after failed attempts

Target of the lab: lock an account for 15 minutes after 5 failed attempts (`deny=5`, `unlock_time=900`).

Review note: the report text mentions `pam_faillock`, but the screenshot of `/etc/pam.d/common-auth` shows a `pam_tally2` line. On Ubuntu 24.04, `pam_tally2` is not available and `pam_faillock` is the supported module. The lockout was not tested in the lab.

Reference configuration for Ubuntu 24.04 (not taken from the report, to be tested before relying on it):

`/etc/security/faillock.conf`
```
deny = 5
unlock_time = 900
```

`/etc/pam.d/common-auth` (order matters, keep a root session open while testing to avoid locking yourself out)
```
auth    required                        pam_faillock.so preauth
auth    [success=1 default=ignore]      pam_unix.so nullok
auth    [default=die]                   pam_faillock.so authfail
auth    sufficient                      pam_faillock.so authsucc
```

Check and reset: `sudo faillock --user <username>` and `sudo faillock --user <username> --reset`
