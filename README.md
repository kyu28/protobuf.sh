# protobuf.sh
Shell scripts to play with protobuf

## pbdecode.sh
Decode protocol buffer wire format with POSIX Shell  
This script is used for quickly glancing the content of protobuf messages during debugging, and it does not provide message parsing based on `.proto` files.
### Dependency
```
one of below
+ xxd
+ od
+ hexdump
+ busybox
```

### Usage
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

### Note for bytes, string, embedded messages
Bytes, string, embedded messages are encoded to bytes.  
Without `.proto` file, it's impossible to distinguish between bytes, string and embedded messages.  
`pbdecode.sh` will try treating bytes as embedded messages and decoding recursively.  
If a bytes field cannot be decoded, `pbdecode.sh` will treat it as a string.  

### Note for repeated fields
#### Varint, fixed64, fixed32
`[packed=true]` option is default for proto3.  
Repeated varints, fixed64s and fixed32s will be encoded to bytes.
e.g.  
Single int32  
```proto
message A {
  int32 num = 1;
}
```
```
{ "num": 64 } => x08(field:1, type:varint) x40(64)
```
Repeated int32
```proto
message B {
  repeated int32 num = 1;
}
```
```
{ "num": [64, 65] } => x0a(field:1, type:bytes) x02(length:2) x40(64) x41(65)
```
`pbdecode.sh` will treat packed repeated fields as bytes.

#### Message
> Ordinary (not packed) repeated fields emit one record for every element of the field.

Due to implementation, output JSON will also emit one record for every element of the field.  
> ECMA-404: 6 Objects  
The JSON syntax does not impose any restrictions on the strings used as names,
 does not require that name strings be unique...

e.g.  
```proto
message C {
  repeated D msgs = 1;
}

message D {
  int32 num = 1;
}
```
```
x0a(field:1, type:bytes) x02(length:2) x08(field:1, type:varint) x40(64)
x0a(field:1, type:bytes) x02(length:2) x08(field:1, type:varint) x41(65)
=> {"1":{"1":64},"1":{"1":65}}
```

## pq.sh
Just like jq, but it process the output of `protoc --decode_raw`  

### Usage
```sh
pq.sh [fields...]
```
  
`protoc --decode_raw` outputs like this:
```
1: 114514
2: "Hello world"
3 {
  1: 1919810
}
```
To get 3, just run
```
$ pq.sh 3
3 {
  1: 1919810
}
```
To get 3.1, just run
```
$ pq.sh 3 1
1919810
```
