<div align="center">

「 强大的Swift Web API请求框架 」

</div>

[下载安装](#下载安装)

[功能](#功能)

[支持解析的类型](#支持解析的类型)

[使用方法](#使用方法)

# 下载安装
直接下载后放入项目中

# 功能
- 请求本地文件并解析
- 请求Web服务器并进行解析

# 支持解析的类型

普通文本：Int, Bool, String

JSON文件：NativeJsonObject,自定义struct

XML文件：NativeXmlObject

# 使用方法

## 网络请求解析为普通类型

解析为Int类型

    // 网页只返回单独的一个普通文本 如
    // 1
    WebAPI.post(Int.self, "https://xxxxx", dic) { result in
         print(result) // result是一个T?类型对象
    }

直接解析为字符串

    var dic = ["userId":"300","title":"My urgent task","completed": "false"] // 创建参数一个字典
    WebAPI.post(String.self, "https://jsonplaceholder.typicode.com/todos", dic) { result in
         print(result) // result是一个T?类型对象
    }

## 网络请求解析为自定义结构体类型(Struct只用编写需要的字段，无需完全匹配)
定义结构体

    struct Result: Decodable, Encodable {
       let id: Int
       let userId: String
       let title: String
       let completed: String
    
    }

接受Option\<T>参数

    var dic = ["userId":"300","title":"My urgent task","completed": "false"] // 创建参数一个字典
    WebAPI.post(Result.self, "https://jsonplaceholder.typicode.com/todos", dic) { result in
         print(result) // result是一个T?类型对象
    }


自动解包Option\<T>

    var dic = ["userId":"300","title":"My urgent task","completed": "false"] // 创建参数一个字典
    WebAPI.post(Result.self, "https://jsonplaceholder.typicode.com/todos", dic,{ result in
         print(result) // 解析成功
    },{
        // 文件无法解析为目标类型或文件不存在
    }) 

## 网络请求解析为字典类型(会获取到所有字段)

默认提供XML字典和JSON字典

解析类型填写NativeJsonObject.self或NativeXmlObject.self即可