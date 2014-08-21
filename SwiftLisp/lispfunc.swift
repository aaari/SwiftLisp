//
//  lispfunc.swift
//  HelloSwift
//
//  Created by toru on 8/10/14.
//  Copyright (c) 2014 toru. All rights reserved.
//

import Foundation


/*** Lispの関数 ***/

func cons(car_val: LispObj, cdr_val: LispObj) -> LispObj {
    var newcell = ConsCell(car: car_val, cdr: cdr_val);
    return newcell;
}

func eq(exp: LispObj, str: String) -> Bool {
    if let tmp = exp as? LispStr {
        return tmp.value == str;
    } else {
        return false;
    }
}

func car(exp: LispObj) -> LispObj {
    if let operand = exp.listp() {
        return operand.car;
    } else {
        return Error(message: "at (car " + exp.toStr() + ")");
    }
}
func cdr(exp: LispObj) -> LispObj {
    if let operand = exp.listp() {
        return operand.cdr;
    } else {
        return Error(message: "at (cdr " + exp.toStr() + ")");
    }
}

func cadr(exp: LispObj) -> LispObj {
    return car(cdr(exp));
}

func cddr(exp: LispObj) -> LispObj {
    return cdr(cdr(exp));
}


func concat(list: LispObj, lastcell: LispObj) -> LispObj {
    if list is Nil {
        return lastcell;
    } else if let tmpcell = list.listp() {
        return cons(tmpcell.car, concat(tmpcell.cdr, lastcell));
    } else {
        // tmpcell == atom のとき(呼ばれないはず)
        return cons(list, lastcell);
    }
}