//
//  types.swift
//  HelloSwift
//
//  Created by toru on 8/10/14.
//  Copyright (c) 2014 toru. All rights reserved.
//

import Foundation


protocol LispObj {
    func toStr() -> String
    
    // list ならば キャストして値を返す
    func listp() -> ConsCell?
}

/*
Singleton の例
参考: http://qiita.com/1024jp/items/3a7bc437af3e79f74505
*/
class Nil: LispObj {
    init() {
    }
    
    class var sharedInstance: Nil {
    struct Singleton {
        private static let instance = Nil()
        }
        return Singleton.instance
    }
    
    func toStr() -> String {
        return "nil";
    }
    
    func listp() -> ConsCell? {
        return nil;
    }
}


/*
Stringクラスの拡張
str.substring(from, to) を str[from...to] で実現する
参考: http://stackoverflow.com/questions/24044851/how-do-you-use-string-substringwithrange-or-how-do-ranges-work-in-swift
*/
extension String {
    subscript (r: Range<Int>) -> String {
        get {
            let startIndex = advance(self.startIndex, r.startIndex)
            let endIndex = advance(startIndex, r.endIndex - r.startIndex)
            
            return self[Range(start: startIndex, end: endIndex)]
        }
    }
}


// instanceof -> is
// cast -> as or as?  asは強制、as?は失敗するとnilが入る
// AnyObject という何でも表す型がある?
// Any という型もある

class ConsCell: LispObj {
    var car: LispObj;
    var cdr: LispObj;
    
    init(car: LispObj, cdr: LispObj) {
        self.car = car;
        self.cdr = cdr;
    }
    
    func toStr() -> String {
        var returnValue: String = "";
        returnValue += "(";
        var tmpcell = self;
        
        while (true) {
            returnValue += tmpcell.car.toStr();
            
            if let cdrcell = tmpcell.cdr.listp() {
                tmpcell = cdrcell;
            } else if tmpcell.cdr is Nil {
                break;
            } else {
                returnValue += ".";
                returnValue += tmpcell.cdr.toStr();
                break;
            }
            returnValue += " ";
        }
        returnValue += ")"
        
        return returnValue;
    }
    
    func listp() -> ConsCell? {
        return self;
    }
}

class Symbol: LispObj {
    var name: String;
    init(name: String) {
        self.name = name;
    }
    
    func toStr() -> String {
        return name;
    }
    
    func listp() -> ConsCell? {
        return nil;
    }
}

class LispNum: LispObj {
    var value: Int;
    init(value: Int) {
        self.value = value;
    }
    
    func toStr() -> String {
        return String(value);
    }
    
    func listp() -> ConsCell? {
        return nil;
    }
}

class LispStr: LispObj {
    var value: String;
    init(value: String) {
        self.value = value;
    }
    
    func toStr() -> String {
        return "\"" + value + "\"";
    }
    
    func listp() -> ConsCell? {
        return nil;
    }
}

class Error: LispObj {
    var message: String;
    init(message: String) {
        self.message = message;
    }
    
    func toStr() -> String {
        return "Error: " + message;
    }
    
    func listp() -> ConsCell? {
        return nil;
    }
}

class Environment: LispObj {
    var env: [Dictionary<String, LispObj>] = [];
    init() {
        env.insert(Dictionary<String, LispObj>(), atIndex: 0);
    }
    
    func toStr() -> String {
        return "[env]";
    }
    
    func add(variable: String, val: LispObj) {
        env[0].updateValue(val, forKey: variable)
    }
    
    func addPrimitive(name: String) {
        self.add(name, val: ConsCell(car: LispStr(value: PRIMITIVE), cdr: Symbol(name: name)));
    }
    
    func get(name: String) -> LispObj {
        for dic in env {
            if let value = dic[name] {
                return value;
            }
        }
        return NIL;
    }
    
    func copy() -> Environment {
        // Swiftは値渡しのようなので、以下でコピーになる
        var newenv = Environment()
        newenv.env = self.env;
        return newenv;
    }
    
    func extend(lambda_params: LispObj, operand: LispObj) -> Environment? {
        env.insert(Dictionary<String, LispObj>(), atIndex: 0)
        if (addlist(lambda_params, operand: operand)) {
            return self;
        } else {
            return nil;
        }
    }
    
    func addlist(params: LispObj, operand: LispObj) -> Bool {
        if let params_cell = params.listp() {  // && で繋げて書くと上手くいかない(なぜ??)
            if let operand_cell = operand.listp() {
                
                // これだと param_cell.car がLispStrのとき不具合になりそう
                self.add(params_cell.car.toStr(), val: operand_cell.car);
                return addlist(params_cell.cdr, operand: operand_cell.cdr);
            } else {
                // TODO: サイズが合わない場合のエラー処理
                return false;
            }
        } else {
            if let operand_cell = operand.listp() {
                // TODO: サイズが合わない場合のエラー処理
                return false;
            } else {
                return true;
            }
        }
    }
    
    func listp() -> ConsCell? {
        return nil
    }
}