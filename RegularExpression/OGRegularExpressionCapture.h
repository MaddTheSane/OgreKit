/*
 * Name: OGRegularExpressionCapture.h
 * Project: OgreKit
 *
 * Creation Date: Jun 24 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#ifndef NOT_RUBY
#	define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
#	define HAVE_CONFIG_H
#endif
#import <OgreKit/onigmo.h>


// constants
extern NSString	* const OgreCaptureException;


@class OGRegularExpression, OGRegularExpressionEnumerator, OGRegularExpressionMatch, OGRegularExpressionCapture;


@protocol OGRegularExpressionCaptureVisitor <NSObject>
- (void)visitAtFirstCapture:(OGRegularExpressionCapture *)aCapture;
- (void)visitAtLastCapture:(OGRegularExpressionCapture *)aCapture;
@end


/* capture history tree example
calculator with four operations '+', '-', '*', '/' and parentheses '(', ')' 

static NSString *const calcRegex = @"\\g<e>(?<e>\\g<t>(?:(?@<e1>\\+\\g<t>)|(?@<e2>\\-\\g<t>))*){0}(?<t>\\g<f>(?:(?@<t1>\\*\\g<f>)|(?@<t2>/\\g<f>))*){0}(?<f>\\(\\g<e>\\)|(?@<f2>\\d+(?:\\.\\d*)?)){0}";

 calcRegex corresponds to the following EBNF

    <e> ::= <t> { + <t> | - <t> }
    <t> ::= <f> { * <f> | / <f> }
    <f> ::= ( <e> )
        | NUMBERS
 
 Note 1: Left recursive rules is forbidden.
 Note 2: The upper limit of number/kinds of capture history "(?@...)" is 31.
         eg. in the foregoing example, the number of capture history is 5 (e1, e2, t1, t2, f3) <= 31.
 */
@interface OGRegularExpressionCapture : NSObject <NSCopying, NSCoding>
{
	OnigCaptureTreeNode         *_captureNode;      // Oniguruma capture tree node
    NSUInteger                  _index,             // マッチした順番
                                _level;             // 深さ
	OGRegularExpressionMatch	*_match;            // 生成主のOGRegularExpressionMatchオブジェクト
	OGRegularExpressionCapture	*_parent;           // 親
}

/*********
 * 諸情報 *
 *********/
// グループ番号
@property (nonatomic, readonly) NSUInteger groupIndex;

// グループ名
@property (nonatomic, readonly, copy) NSString *groupName;

// 何番目の子要素であるか 0,1,2,...
@property (nonatomic, readonly) NSUInteger index;

// Depth (深さ)
// 0: root
@property (nonatomic, readonly) NSUInteger level;

// 子要素の数
@property (nonatomic, readonly) NSUInteger numberOfChildren;

// Child elements us (子要素たち)
// return nil in the case of numberOfChildren == 0
@property (nonatomic, readonly, copy) NSArray *children;

// index番目の子要素
- (OGRegularExpressionCapture*)childAtIndex:(NSUInteger)index;

// match
@property (nonatomic, readonly, copy) OGRegularExpressionMatch *match;

// description
@property (nonatomic, readonly, copy) NSString *description;

/******************
 * String (文字列) *
 ******************/
// String that became the match of subject (マッチの対象になった文字列)
@property (nonatomic, readonly, copy) NSString *targetString;
@property (nonatomic, readonly, copy) NSAttributedString *targetAttributedString;

// Matched string (マッチした文字列)
@property (nonatomic, readonly, copy) NSString *string;
@property (nonatomic, readonly, copy) NSAttributedString *attributedString;

/*******
 * 範囲 *
 *******/
// Range of matched string (マッチした文字列の範囲)
@property (nonatomic, readonly) NSRange range;

/************************
* adapt Visitor pattern *
*************************/
- (void)acceptVisitor:(id <OGRegularExpressionCaptureVisitor>)aVisitor;

@end
