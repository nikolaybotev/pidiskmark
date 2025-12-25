# pidiskmark

A CrystalDiskMark equivalent benchmark script for Raspberry Pi OS Linux.

**Prerequisites**

```sh
sudo apt install fio
```

**Usage**

```sh
./pidiskmark.sh test_file_name [size]
```

* `test_file_name` A file name on the filesystem you want to test; this file should *not* already exist, but should be in an existing directory that can be written to.
* `size` The size of the test file; `512m` by default. This argument supports the size suffixes supported by the `fio` `--size` argument.

## Background

Inspired by the great answers here:

https://unix.stackexchange.com/q/93791

One of the answers demonstrated how to use fio: https://unix.stackexchange.com/a/392091
* However, there was no time cap on the test.

The other answer provided a script and demonstrated how the fio output can be summarized in beautiful form: https://unix.stackexchange.com/a/480191
 * However, this script did not work as-in on Raspberry Pi OS.

This led me to write the above script, which combines the best of both answers, and should work out of the box on Raspberry Pi OS.

---

Originally published as a gist at https://gist.github.com/nikolaybotev/81c97a4fd9b65cb8d33ac9eeb97da9d9
