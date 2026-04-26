/// Encryption and conversion API for JavaScript comic sources.
///
/// This file provides various encryption and encoding functions that can be
/// called from JavaScript code running in comic sources.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:enough_convert/enough_convert.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/block/modes/cfb.dart';
import 'package:pointycastle/block/modes/ecb.dart';
import 'package:pointycastle/block/modes/ofb.dart';
import 'package:pointycastle/block/aes.dart';

/// Mixin providing encryption/decryption API implementation.
mixin class NekoConvertApi {
  /// Handle convert callbacks from JavaScript.
  dynamic _convert(Map<String, dynamic> data) {
    String type = data["type"];
    var value = data["value"];
    bool isEncode = data["isEncode"] ?? true;
    
    try {
      switch (type) {
        case "utf8":
          return isEncode ? utf8.encode(value) : utf8.decode(value);
          
        case "gbk":
          final codec = const GbkCodec();
          return isEncode
              ? Uint8List.fromList(codec.encode(value))
              : codec.decode(value);
              
        case "base64":
          return isEncode ? base64Encode(value) : base64Decode(value);
          
        case "base64url":
          return isEncode 
              ? base64Url.encode(value is String ? utf8.encode(value) : value)
              : base64Url.decode(value);
              
        case "md5":
          if (value is String) value = utf8.encode(value);
          return Uint8List.fromList(md5.convert(value).bytes);
          
        case "sha1":
          if (value is String) value = utf8.encode(value);
          return Uint8List.fromList(sha1.convert(value).bytes);
          
        case "sha256":
          if (value is String) value = utf8.encode(value);
          return Uint8List.fromList(sha256.convert(value).bytes);
          
        case "sha512":
          if (value is String) value = utf8.encode(value);
          return Uint8List.fromList(sha512.convert(value).bytes);
          
        case "hmac":
          return _hmac(data);
          
        case "aes-ecb":
          return _aesEcb(value, data["key"], isEncode);
          
        case "aes-cbc":
          return _aesCbc(value, data["key"], data["iv"], isEncode);
          
        case "aes-cfb":
          return _aesCfb(value, data["key"], data["iv"], data["blockSize"] ?? 16, isEncode);
          
        case "aes-ofb":
          return _aesOfb(value, data["key"], data["iv"], data["blockSize"] ?? 16, isEncode);
          
        case "aes-ctr":
          return _aesCtr(value, data["key"], data["iv"], isEncode);
          
        default:
          throw "Unsupported conversion type: $type";
      }
    } catch (e) {
      if (e is String) {
        throw "Convert error ($type): $e";
      }
      rethrow;
    }
  }

  /// HMAC calculation.
  dynamic _hmac(Map<String, dynamic> data) {
    var key = data["key"];
    var hash = data["hash"];
    var isString = data['isString'] == true;
    
    if (key is String) key = utf8.encode(key);
    
    Hmac hmac;
    switch (hash) {
      case "md5":
        hmac = Hmac(md5, key);
        break;
      case "sha1":
        hmac = Hmac(sha1, key);
        break;
      case "sha256":
        hmac = Hmac(sha256, key);
        break;
      case "sha512":
        hmac = Hmac(sha512, key);
        break;
      default:
        throw "Unsupported HMAC hash: $hash";
    }
    
    var input = data["value"];
    if (input is String) input = utf8.encode(input);
    
    if (isString) {
      return hmac.convert(input).toString();
    } else {
      return Uint8List.fromList(hmac.convert(input).bytes);
    }
  }

  /// AES ECB mode encryption/decryption.
  Uint8List _aesEcb(dynamic value, dynamic key, bool isEncode) {
    if (key is String) key = utf8.encode(key);
    if (value is String) value = utf8.encode(value);
    if (value is! Uint8List) value = Uint8List.fromList(value);
    
    var cipher = ECBBlockCipher(AESEngine());
    cipher.init(isEncode, KeyParameter(Uint8List.fromList(key)));
    
    var offset = 0;
    var result = Uint8List(value.length);
    while (offset < value.length) {
      offset += cipher.processBlock(
        value,
        offset,
        result,
        offset,
      );
    }
    return result;
  }

  /// AES CBC mode encryption/decryption.
  Uint8List _aesCbc(dynamic value, dynamic key, dynamic iv, bool isEncode) {
    if (key is String) key = utf8.encode(key);
    if (value is String) value = utf8.encode(value);
    if (value is! Uint8List) value = Uint8List.fromList(value);
    if (iv is String) iv = utf8.encode(iv);
    if (iv is! Uint8List) iv = Uint8List.fromList(iv);
    
    var cipher = CBCBlockCipher(AESEngine());
    cipher.init(isEncode, ParametersWithIV(KeyParameter(Uint8List.fromList(key)), Uint8List.fromList(iv)));
    
    var offset = 0;
    var result = Uint8List(value.length);
    while (offset < value.length) {
      offset += cipher.processBlock(
        value,
        offset,
        result,
        offset,
      );
    }
    return result;
  }

  /// AES CFB mode encryption/decryption.
  Uint8List _aesCfb(dynamic value, dynamic key, dynamic iv, int blockSize, bool isEncode) {
    if (key is String) key = utf8.encode(key);
    if (value is String) value = utf8.encode(value);
    if (value is! Uint8List) value = Uint8List.fromList(value);
    if (iv is String) iv = utf8.encode(iv);
    if (iv is! Uint8List) iv = Uint8List.fromList(iv);
    
    var cipher = CFBBlockCipher(AESEngine(), blockSize);
    cipher.init(isEncode, ParametersWithIV(KeyParameter(Uint8List.fromList(key)), Uint8List.fromList(iv)));
    
    var offset = 0;
    var result = Uint8List(value.length);
    while (offset < value.length) {
      offset += cipher.processBlock(
        value,
        offset,
        result,
        offset,
      );
    }
    return result;
  }

  /// AES OFB mode encryption/decryption.
  Uint8List _aesOfb(dynamic value, dynamic key, dynamic iv, int blockSize, bool isEncode) {
    if (key is String) key = utf8.encode(key);
    if (value is String) value = utf8.encode(value);
    if (value is! Uint8List) value = Uint8List.fromList(value);
    if (iv is String) iv = utf8.encode(iv);
    if (iv is! Uint8List) iv = Uint8List.fromList(iv);
    
    var cipher = OFBBlockCipher(AESEngine(), blockSize);
    cipher.init(isEncode, ParametersWithIV(KeyParameter(Uint8List.fromList(key)), Uint8List.fromList(iv)));
    
    var offset = 0;
    var result = Uint8List(value.length);
    while (offset < value.length) {
      offset += cipher.processBlock(
        value,
        offset,
        result,
        offset,
      );
    }
    return result;
  }

  /// AES CTR mode encryption/decryption.
  Uint8List _aesCtr(dynamic value, dynamic key, dynamic iv, bool isEncode) {
    // CTR mode is implemented as OFB with counter-like IV
    return _aesOfb(value, key, iv, 16, isEncode);
  }
}
