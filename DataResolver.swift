//
// Created by LFT on 2022/3/9.
//

import Foundation

class DataResolver {
    private var handlers: [DataHandler] = []

    init() {
        handlers.append(StringDataHandler())
        handlers.append(IntDataHandler())
        handlers.append(BoolDataHandler())
        handlers.append(JsonDataHandler())
        handlers.append(XMLDataHandler())
    }

    public func resolve<T: Decodable>(_ data: Data, _ type: T.Type) -> T? {
        var res: T? = nil;
        for handler in handlers {
            res = res ?? handler.resolve(data, type)
        }
        return res;
    }
}

protocol DataHandler {
    func resolve<T: Decodable>(_ data: Data, _ type: T.Type) -> T?;
}

class XMLDataHandler: NSObject, XMLParserDelegate,DataHandler {
    var level: [(String, Any)] = []
    var res = NSMutableDictionary()

    func resolve<T>(_ data: Data, _ type: T.Type) -> T? where T: Decodable {
        do {
            if (type == NativeXmlObject.self) {
                level = []
                res = NSMutableDictionary()
                level.append(("root", res))
                let parser = XMLParser(data: data)
                parser.delegate = self
                parser.parse()
                return NativeXmlObject(res) as! T;
            }
            return nil
        } catch {

        }
        return nil
    }


    var current = ""

    // 遇到一个开始标签时调用
    func parser(_ parser: XMLParser, didStartElement ele: String,
                namespaceURI: String?, qualifiedName q: String?,
                attributes attrs: [String: String] = [:]) {
        current = ele
        for key in attrs.keys {
            let data = attrs[key]!.trimmingCharacters(in: .whitespacesAndNewlines)
            if (data == "") {
                continue;
            }
            tempList.append((key, data));
        }
    }

    var skip = false
    var tempList: [(String, String)] = []

    // 遇到字符串时调用
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if (skip) {
            skip = false;
            return;
        }
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        level.append(addInfo(current, data))
    }

    func addInfo(_ key: String, _ data: String) -> (String, Any) {
        if let tuple = level.last {
            var inner: Any
            if (tuple.1 is NSMutableDictionary) {
                var dic = tuple.1 as! NSMutableDictionary
                inner = resolveConflict(key, data, dic)
                dic.setValue(inner, forKey: key)
            } else {
                var arr = tuple.1 as! NSMutableArray
                inner = resolveConflict(key, data, arr)
            }
            return (current, inner);
        }

        return ("Error", "Error")
    }

    func resolveConflict(_ key: String, _ data: String, _ dic: NSMutableDictionary) -> Any {
        if (dic[key] == nil) {
            return resolveType(data)
        }
        let obj = dic[key]!;
        let newbe: Any = resolveType(data);
        if (obj is NSMutableArray) {
            let arr = obj as! NSMutableArray
            arr.add(newbe)
            return obj;
        }
        let arr: NSMutableArray = [obj, newbe]
        return arr
    }

    func resolveConflict(_ key: String, _ data: String, _ arr: NSMutableArray) -> Any {
        var item = arr.lastObject!;
        if (item is NSMutableDictionary) {
            var dic = item as! NSMutableDictionary
            var newBe = resolveConflict(key, data, dic)
            dic.setValue(newBe, forKey: key)
            return newBe
        }
        return "Impossible"
    }

    func resolveType(_ data: String) -> Any {
        data == "" ? NSMutableDictionary() : data
    }

    // 遇到结束标签时调用
    func parser(_ parser: XMLParser, didEndElement ele: String,
                namespaceURI: String?, qualifiedName q: String?) {
        level.removeLast()
        if (tempList.count > 0) {
            for (key, val) in tempList {
                addInfo(key, val)
            }
            tempList = []
        }
        skip = true;
    }

}


class JsonDataHandler: DataHandler {
    private let decoder = JSONDecoder()

    func resolve<T: Decodable>(_ data: Data, _ type: T.Type) -> T? {
        do {
            if (type == NativeJsonObject.self) {
                var dic = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                return NativeJsonObject(dic) as! T
            }
            return try decoder.decode(T.self, from: data)
        } catch {

        }
        return nil
    }
}

class StringDataHandler: DataHandler {
    func resolve<T>(_ data: Data, _ type: T.Type) -> T? where T: Decodable {
        if (T.self == String.self) {
            let res = String(data: data, encoding: .utf8) ?? "-1"
            return res as! T?
        }
        return nil
    }
}

class IntDataHandler: DataHandler {
    func resolve<T>(_ data: Data, _ type: T.Type) -> T? where T: Decodable {
        if (T.self == Int.self) {
            let dataString = String(data: data, encoding: .utf8) ?? "-1"
            let res: Int? = Int(dataString)
            return res as! T?
        }
        return nil
    }
}

class BoolDataHandler: DataHandler {
    func resolve<T>(_ data: Data, _ type: T.Type) -> T? where T: Decodable {
        if (T.self == Int.self) {
            let dataString = String(data: data, encoding: .utf8) ?? "-1"
            let res: Bool? = Bool(dataString)
            return res as! T?
        }
        return nil
    }
}

struct NativeJsonObject: Decodable {
    var dic: NSDictionary

    init(_ dic: NSDictionary) {
        self.dic = dic
    }

    init(from decoder: Decoder) throws {
        self.dic = [:]
    }

    dynamic public subscript(key: Any) -> Any? {
        get {
            return dic[key]
        }
    }
}

struct NativeXmlObject: Decodable {
    var dic: NSDictionary

    init(_ dic: NSDictionary) {
        self.dic = dic
    }

    init(from decoder: Decoder) throws {
        self.dic = [:]
    }

    dynamic public subscript(key: Any) -> Any? {
        get {
            return dic[key]
        }
    }
}