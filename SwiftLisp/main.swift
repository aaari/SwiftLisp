import Foundation

let NIL = Nil.sharedInstance;

let PRIMITIVE = "*** PRIMITIVE ***";
let LAMBDA = "*** LAMBDA ***";

// 解析結果のトークンリストを入れる配列
var tokenlist: [String] = [];

// どこまで読み込んだかを表す配列
var tokenIndex = 0;

func get_token() -> String {
    if tokenlist.count <= tokenIndex {
        return ""; //"";
    } else {
        var s = tokenlist[tokenIndex];
        tokenIndex = tokenIndex + 1;
        if s == "" {
            return get_token();
        } else {
            return s;
        }
    }
}

func read_next(var token: String) -> LispObj {
    var carexp: LispObj, cdrexp: LispObj;
    var list: LispObj = NIL;
    
    if token == "" {
        return NIL;
    }
    if (token != "(") {  // "(" じゃないときの処理
        if let n = token.toInt() {
            return LispNum(value: n);
        } else {
            let prefix = token.hasPrefix("\"");
            let suffix = token.hasSuffix("\"");
            let length = token.utf16Count;
            
            if prefix && suffix {  // "hogehoge" のようにセミコロンで囲われている場合
                if length > 2 {
                    return LispStr(value: token[1...token.utf16Count-2]);
                } else {
                    return LispStr(value: "");
                }
            } else if prefix || suffix {  // "hogehoge のように片方だけセミコロンが付いている場合
                return Error(message: "wrong String:" + token);
            } else {
                return Symbol(name: token);
            }
        }
    }
    
    
    token = get_token();  // ( の次のトークンを取得
    while (true) {  // "(" から始まるとき
        if (token == ")") {
            return list;
        }
        
        carexp = read_next(token);  // 読み込んだトークンをcar部分として処理
        token = get_token();     // 次のトークン取得
        if (token == ".") {       // ペアの場合
            token = get_token();
            cdrexp = read_next(token);  // 取得した次のトークンを cdr にセット
            
            token = get_token();   // ペアの後は ) がくるはず
            if token != ")" {
                // エラー処理を書く
                println(") required!");
            }
            return ConsCell(car: carexp, cdr: cdrexp);
        }
        
        list = concat(list, cons(carexp, NIL));
        //        break;
    }
    
}

/*
標準入力から文字列取得
// TODO: 括弧の数チェッカーをここに作ってループする。右括弧の方が多ければエラーにする
*/
func read() -> String {
    var tmp = NSFileHandle.fileHandleWithStandardInput();
    
    var rawdata = tmp.availableData;
    var str = NSString(data: rawdata, encoding: NSUTF8StringEncoding);
    
    return str;
}

func tokenize(str: String) { //-> ([String], Int) {
    // ' (quote記号を (quote  ... ) に置き換え
    
    var str2 = ""
    var quoteFlag = false
    for a in str {
        if a == "'" {
            str2 += "(quote "
            quoteFlag = true
        } else if a == ")" && quoteFlag {
            str2 += "))"
            quoteFlag = false;
        } else {
            str2 += a
        }
    }
    
    // "(" と ")" を空白付きに変換
    let replacedStr = str2
        .stringByReplacingOccurrencesOfString("(", withString: " ( ", options: nil, range: nil)
        .stringByReplacingOccurrencesOfString(")", withString: " ) ", options: nil, range: nil)
        .stringByReplacingOccurrencesOfString("\n", withString: " ", options: nil, range: nil);
    
    tokenlist = replacedStr.componentsSeparatedByString(" ");
    tokenIndex = 0;
}

func parse() -> LispObj {
    var c: LispObj;
    c = read_next(get_token());
    return c;
}

func get(str: String, env: Environment) -> LispObj {
    return env.get(str);
}

func def_var(variable: String, val: LispObj, var env: Environment) {
    env.add(variable, val: val);
}
func def_var(variable: LispObj, val: LispObj, env: Environment) {
    if let symbol = variable as? Symbol {
        def_var(symbol.name, val, env);
    }
}

func eval(exp: LispObj, env: Environment) -> LispObj {
    if exp is Error {
        return exp;
    }
    if exp is Nil || exp is LispNum {  // Nilまたは数値の場合はそのまま返す
        return exp;
    }
    if exp is LispStr { // または文字列の場合もそのまま返す(エディタがエラーになるため、 || の連結は禁止
        return exp;
    }
    if let symbol = exp as? Symbol {  // シンボルならば環境の値を検索して返す
        var value = get(symbol.name, env);
        if !(value is Nil) {
            return value;
        } else {
            return Error(message: "Undefined Value: " + symbol.name);
        }
    }
    
    if let consexp = exp.listp() {
        return apply(consexp.car, consexp.cdr, env);
    }
    
    return Error(message: "something wrong!");
}

func eval_args(exp: LispObj, env: Environment) -> LispObj {
    if let list = exp.listp() {  //  as? ConsCell {
        let car_exp = eval(list.car, env);
        if car_exp is Error {
            return car_exp;
        } else {
            let cdr_exp = eval_args(list.cdr, env);
            if cdr_exp is Error {
                return cdr_exp;
            } else {
                return cons(car_exp, cdr_exp);
            }
        }
    } else {
        return eval(exp, env);
    }
}

func apply(operator_var: LispObj, operand: LispObj, env: Environment) -> LispObj {
    let operator_body = eval(operator_var, env);
    
    let tmp = operand;
    if eq(car(operator_body), PRIMITIVE) {  // プリミティブ関数の場合の処理
        switch cdr(operator_body).toStr() {
        case "car":
            return car(eval(car(operand), env));
        case "cdr":
            return cdr(eval(car(operand), env));
        case "=":
            // (= x 10)
            // (= y "test")
            // (= z (+ 1 2))
            if let variable = car(operand) as? Symbol {  // -> x, y
                let body = cadr(operand);   // 10, "test"
                let value = eval(body, env);
                def_var(variable, value, env);
                
                return variable;
            } else {
                return Error(message: "Wrong type argument: " + car(operand).toStr());
            }
        case "list":
            return eval_args(operand, env);
        case "quote":
            if cdr(operand) is Nil {
                return car(operand);
            } else {
                return Error(message: "Wrong number of arguments: " + operand.toStr());
            }
        case "lambda":
            // lambda式の定義
            // (lambda (x) (+ x 1))
            // operand: ((x) (+ x  1))
            let params = car(operand)   // (x)
            let body = cadr(operand)    // (+ x 1)
            
            let tmp = cons(LispStr(value: LAMBDA), cons(params, cons(body, cons(env.copy(), NIL))));
            return tmp
            
        default:
            return Error(message: "unknown primitive procedure: " + cdr(operator_body).toStr());
        }
    }
    
    if eq(car(operator_body), LAMBDA) {
        // lambda式の実行
        // oparator_body : ("*** lambda ***" (x) (list x x x) [env])
        let lambda_params = cadr(operator_body);    // (x)
        let lambda_body = car(cddr(operator_body)); // (list x x x)
        if let lambda_env = cadr(cddr(operator_body)) as? Environment { // [env]
            let operand_check = eval_args(operand, env);
            if (operand_check is Error) {
                return operand_check;
            }
            
            if let ex_env = lambda_env.extend(lambda_params, operand: operand_check) {
                return eval(lambda_body, ex_env);
            } else {
                return Error(message: "eval lambda params error: " + lambda_params.toStr() + " " + operand.toStr())
            }
        }
    }
    
    return Error(message: "not a function: " + operator_body.toStr());
}

var initialEnv =  Environment();
initialEnv.addPrimitive("car");
initialEnv.addPrimitive("cdr");
initialEnv.addPrimitive("=");
initialEnv.addPrimitive("list");
initialEnv.addPrimitive("quote");
initialEnv.addPrimitive("lambda");

initialEnv.add("test", val: LispNum(value: 1000));
initialEnv.add("test2", val: LispStr(value: "hogehoge"));

var initialexec = "(= x (lambda (y) (list y y y)))"
tokenize(initialexec);
eval(parse(), initialEnv).toStr()


// TODO if文追加
// TODO +-*/追加
// TODO define関数追加
/*
実行
*/
while (true) {
    print(" > ");
    var str = read();
    // TODO: 括弧の数チェッカーをここに作ってループする。右括弧の方が多ければエラーにする
    
    tokenize(str);
    println(eval(parse(), initialEnv).toStr());
}
