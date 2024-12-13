# protobuf.sh
decode protocol buffer wire format with POSIX Shell  
**WORK IN PROGRESS**

## TODO
+ Support repeated fields

## Dependency
```
xxd
```

## Usage
A simple hello world example
```sh
$ printf "\x08\xd2\xfe\x06\x12\x0bHello world\x1a\x04\x08\xc2\x96\x75" | ./pbdecode.sh
{"1":114514,"2":"Hello world","3":{"1":1919810}}
```
More usages
```sh
# load pb from disk
cat demo_msg.pb | pbdecode.sh

# easily debug API with curl
curl http://example.com | pbdecode.sh
```
