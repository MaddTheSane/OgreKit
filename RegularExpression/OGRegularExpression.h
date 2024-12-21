/*
 * Name: OGRegularExpression.h
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2022 Isao Sonobe, All rights reserved.
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

//#define DEBUG_OGRE

/* constants */
// version string
#define OgreVersionString	@"2.1.12"

typedef unsigned OgreOptions;
// compile time options:
extern const OgreOptions	OgreNoneOption;
extern const OgreOptions	OgreSingleLineOption;
extern const OgreOptions	OgreMultilineOption;
extern const OgreOptions	OgreIgnoreCaseOption;
extern const OgreOptions	OgreExtendOption;
extern const OgreOptions	OgreFindLongestOption;
extern const OgreOptions	OgreFindNotEmptyOption;
extern const OgreOptions	OgreNegateSingleLineOption;
extern const OgreOptions	OgreDontCaptureGroupOption;
extern const OgreOptions	OgreCaptureGroupOption;
// (REG_OPTION_POSIX_REGIONは使用しない)
// OgreDelimitByWhitespaceOptionはOgreSimpleMatchingSyntaxの使用時に、空白文字を単語の区切りとみなすかどうか
// 例: @"AAA BBB CCC" -> @"(AAA)|(BBB)|(CCC)"
extern const OgreOptions	OgreDelimitByWhitespaceOption;

#define OgreCompileTimeOptionMask(x)	((x) & (OgreSingleLineOption | OgreMultilineOption | OgreIgnoreCaseOption | OgreExtendOption | OgreFindLongestOption | OgreFindNotEmptyOption | OgreNegateSingleLineOption | OgreDontCaptureGroupOption | OgreCaptureGroupOption | OgreDelimitByWhitespaceOption))

// search time options:
extern const OgreOptions	OgreNotBOLOption;
extern const OgreOptions	OgreNotEOLOption;
extern const OgreOptions	OgreFindEmptyOption;

#define OgreSearchTimeOptionMask(x)		((x) & (OgreNotBOLOption | OgreNotEOLOption | OgreFindEmptyOption))

// replace time options:
extern const OgreOptions	OgreReplaceWithAttributesOption;
extern const OgreOptions	OgreReplaceFontsOption;
extern const OgreOptions	OgreMergeAttributesOption;

#define OgreReplaceTimeOptionMask(x)		((x) & (OgreReplaceWithAttributesOption | OgreReplaceFontsOption | OgreMergeAttributesOption))

// compile time syntax
typedef NS_ENUM(short, OgreSyntax) {
	OgreSimpleMatchingSyntax = 0,
	OgrePOSIXBasicSyntax, 
	OgrePOSIXExtendedSyntax, 
	OgreEmacsSyntax, 
	OgreGrepSyntax, 
	OgreGNURegexSyntax, 
	OgreJavaSyntax, 
	OgrePerlSyntax, 
	OgreRubySyntax
};

// @"\\"
#define	OgreBackslashCharacter			@"\\"
// "\\"
//#define	OgreCStringBackslashCharacter	[NSString stringWithCString:"\\"]
// GUI中の￥マーク
//#define	OgreGUIYenCharacter				[NSString stringWithUTF8String:"\xc2\xa5"]
#define	OgreGUIYenCharacter				@"￥"

// newline character
typedef NS_ENUM(int, OgreNewlineCharacter) {
	OgreNonbreakingNewlineCharacter = -1, 
	OgreUnixNewlineCharacter = 0,		OgreLfNewlineCharacter = 0, 
	OgreMacNewlineCharacter = 1,		OgreCrNewlineCharacter = 1, 
	OgreWindowsNewlineCharacter = 2,	OgreCrLfNewlineCharacter = 2, 
	OgreUnicodeLineSeparatorNewlineCharacter,
	OgreUnicodeParagraphSeparatorNewlineCharacter
};


// exception name
extern NSExceptionName const OgreException;

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator;
@protocol OGStringProtocol;

@interface OGRegularExpression : NSObject <NSCopying, NSCoding>
{
	NSString			*_escapeCharacter;				// \の代替文字
	NSString			*_expressionString;				// 正規表現を表す文字列
	unichar             *_UTF16ExpressionString;        // 正規表現を表すUTF16文字列
	OgreOptions			_options;						// コンパイルオプション
	OgreSyntax			_syntax;						// 正規表現の構文
	
	NSMutableDictionary	*_groupIndexForNameDictionary;	// nameでindexを引く辞書
														// 構造: /(?<a>a+)(?<b>b+)(?<a>c+)/ => {"a" = (1,3), "b" = (2)}
	NSMutableArray		*_nameForGroupIndexArray;		// (index-1)でnameを引く逆引き辞書(配列)
														// 構造: /(?<a>a+)(?<b>b+)(?<a>c+)/ => ("a", "b", "a")
	regex_t				*_regexBuffer;					// 鬼車正規表現構造体
}

/****************************
 * creation, initialization *
 ****************************/
//  Arguments:
//   expressionString: 正規表現を表す文字列
//   options: オプション(後述参照)
//   syntax: 構文(後述参照)
//   escapeCharacter: \の代替文字
//  Return value:
//   success: a pointer to OGRegularExpression instance
//   error:  exception raised
/*
 options:
  OgreNoneOption				no option
  OgreSingleLineOption			'^' -> '\A', '$' -> '\z', '\Z' -> '\z'
  OgreMultilineOption			'.' match with newline
  OgreIgnoreCaseOption			ignore case (case-insensitive)
  OgreExtendOption				extended pattern form
  OgreFindLongestOption			find longest match
  OgreFindNotEmptyOption		ignore empty match
  OgreNegateSingleLineOption	clear OgreSINGLELINEOption which is default on
								in OgrePOSIXxxxxSyntax, OgrePerlSyntax and OgreJavaSyntax.
  OgreDontCaptureGroupOption	named group only captured.  (/.../g)
  OgreCaptureGroupOption		named and no-named group captured. (/.../G)
  OgreDelimitByWhitespaceOption	delimit words by whitespace in OgreSimpleMatchingSyntax
  								@"AAA BBB CCC" <=> @"(AAA)|(BBB)|(CCC)"
  
 syntax:
  OgrePOSIXBasicSyntax		POSIX Basic RE 
  OgrePOSIXExtendedSyntax	POSIX Extended RE
  OgreEmacsSyntax			Emacs
  OgreGrepSyntax			grep
  OgreGNURegexSyntax		GNU regex
  OgreJavaSyntax			Java (Sun java.util.regex)
  OgrePerlSyntax			Perl
  OgreRubySyntax			Ruby (default)
  OgreSimpleMatchingSyntax	Simple Matching
  
 escapeCharacter:
  OgreBackslashCharacter		@"\\" Backslash (default)
  OgreGUIYenCharacter			[NSString stringWithUTF8String:"\xc2\xa5"] Yen Mark
 */

+ (instancetype)regularExpressionWithString:(NSString*)expressionString;
+ (instancetype)regularExpressionWithString:(NSString*)expressionString
									options:(OgreOptions)options;
+ (instancetype)regularExpressionWithString:(NSString*)expressionString
									options:(OgreOptions)options
									 syntax:(OgreSyntax)syntax
							escapeCharacter:(NSString*)character;
	
- (instancetype)initWithString:(NSString*)expressionString;
- (instancetype)initWithString:(NSString*)expressionString
					   options:(OgreOptions)options;
- (instancetype)initWithString:(NSString*)expressionString
					   options:(OgreOptions)options
						syntax:(OgreSyntax)syntax
			   escapeCharacter:(NSString*)character;


/*************
 * accessors *
 *************/
// 正規表現を表している文字列をコピーして返す。変更するにはrecompileが必要。
@property (readonly, copy) NSString *expressionString;
// 現在有効なオプション。変更するにはrecompileが必要。
@property (readonly) OgreOptions options;
// 現在使用している正規表現の構文。変更するにはrecompileが必要。
@property (readonly) OgreSyntax syntax;
// エスケープ文字 @"\\" の代替文字。変更するにはrecompileが必要。変更すると数割遅くなります。
@property (readonly, copy) NSString *escapeCharacter;

// capture groupの数
@property (readonly, nonatomic) unsigned numberOfGroups;
// named groupの数
@property (readonly, nonatomic) unsigned numberOfNames;
// nameの配列
// named groupを使用していない場合はnilを返す。
@property (readonly, copy) NSArray<NSString*>* names;

// 現在のデフォルトのエスケープ文字。初期値は @"\\"(GUI中の\記号)
+ (NSString*)defaultEscapeCharacter;
// デフォルトのエスケープ文字を変更する。変更すると数割遅くなります。
// 変更前に作成されたインスタンスには影響を与えない。
// character が使用できない文字の場合には例外を発生する。
+ (void)setDefaultEscapeCharacter:(NSString*)character;
@property (class, readwrite, nonatomic, copy) NSString *defaultEscapeCharacter;

// 現在のデフォルトの正規表現構文。初期値は OgreRubySyntax
+ (OgreSyntax)defaultSyntax;
// デフォルトの正規表現構文を変更する。
// 変更前に作成されたインスタンスには影響を与えない。
+ (void)setDefaultSyntax:(OgreSyntax)syntax;
@property (class, readwrite) OgreSyntax defaultSyntax;

// OgreKitのバージョン文字列を返す
+ (NSString*)version;
@property (class, readonly, copy) NSString* version;
// oniguruma/onigmoのバージョン文字列を返す
+ (NSString*)onigurumaVersion;
@property (class, readonly, copy) NSString* onigurumaVersion;

// description
- (NSString*)description;


/*******************
 * Validation test *
 *******************/
// 正しければ YES、正しくなければ NO を返す。
/* 正しくない理由を知りたい場合は、次のようにして例外を拾って下さい。
	NS_DURING
		OGRegularExpression	*rx = [OGRegularExpression regularExpressionWithString:expressionString];
	NS_HANDLER
		// 例外処理
		NSLog(@"%@ caught\n", [localException name]);
		NSLog(@"reason = \"%@\"\n", [localException reason]);
	NS_ENDHANDLER
 */
+ (BOOL)isValidExpressionString:(NSString*)expressionString;
+ (BOOL)isValidExpressionString:(NSString*)expressionString
	options:(OgreOptions)options;
+ (BOOL)isValidExpressionString:(NSString*)expressionString
	options:(OgreOptions)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;


/**********
 * Search *
 **********/
/*
 options:
  OgreNotBOLOption			string head(str) isn't considered as begin of line
  OgreNotEOLOption			string end (end) isn't considered as end of line
  OgreFindEmptyOption		allow empty match being next to not empty matchs
	e.g. 
	regex = [OGRegularExpression regularExpressionWithString:@"[a-z]*" options:compileOptions];
	NSLog(@"%@", [regex replaceAllMatchesInString:@"abc123def" withString:@"(\\0)" options:searchOptions]);
	
	compileOptions			searchOptions				replaced string
 1. OgreFindNotEmptyOption  OgreNoneOption				(abc)123(def)
							(or OgreFindEmptyOption)		
 2. OgreNoneOption			OgreNoneOption				(abc)1()2()3(def)
 3. OgreNoneOption			OgreFindEmptyOption			(abc)()1()2()3(def)()
 
	(comment: OgreFindEmptyOption is useful in the case of a matching like [a-z]+|\z.)
 */
// 最初にマッチした部分の OGRegularExpressionMatch オブジェクトを返す。
// マッチしなかった場合は nil を返す。
- (OGRegularExpressionMatch*)matchInString:(NSString*)string;
- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	range:(NSRange)range;
- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	options:(OgreOptions)options;
- (OGRegularExpressionMatch*)matchInString:(NSString*)string
	options:(OgreOptions)options
	range:(NSRange)searchRange;

- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString;
- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString 
	range:(NSRange)range;
- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString 
	options:(OgreOptions)options;
- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString
	options:(OgreOptions)options
	range:(NSRange)searchRange;

- (OGRegularExpressionMatch*)matchInOGString:(id<OGStringProtocol>)string 
	options:(OgreOptions)options
	range:(NSRange)searchRange;

// 全てのマッチした部分の OGRegularExpressionMatch オブジェクトを
// 列挙する OGRegularExpressionEnumerator オブジェクトを返す。
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string;
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string 
	options:(OgreOptions)options;
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string
	range:(NSRange)searchRange;
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string 
	options:(OgreOptions)options
	range:(NSRange)searchRange;
	
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString;
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString 
	options:(OgreOptions)options;
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString
	range:(NSRange)searchRange;
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString 
	options:(OgreOptions)options
	range:(NSRange)searchRange;

- (NSEnumerator*)matchEnumeratorInOGString:(id<OGStringProtocol>)string 
	options:(OgreOptions)options
	range:(NSRange)searchRange;
	
// 全てのマッチした部分の OGRegularExpressionMatch オブジェクトを
// 要素に持つ NSArray オブジェクトを返す。順序はマッチした順。
// ([[self matchEnumeratorInString:string] allObject]と同じ)
// マッチしなかった場合は nil を返す。
- (NSArray*)allMatchesInString:(NSString*)string;
- (NSArray*)allMatchesInString:(NSString*)string
	options:(OgreOptions)options;
- (NSArray*)allMatchesInString:(NSString*)string
	range:(NSRange)searchRange;
- (NSArray*)allMatchesInString:(NSString*)string
	options:(OgreOptions)options
	range:(NSRange)searchRange;

- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString;
- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString
	options:(OgreOptions)options;
- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString
	range:(NSRange)searchRange;
- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString
	options:(OgreOptions)options
	range:(NSRange)searchRange;

- (NSArray*)allMatchesInOGString:(id<OGStringProtocol>)string
	options:(OgreOptions)options
	range:(NSRange)searchRange;


/***********
 * Replace *
 ***********/
// 文字列targetString中の正規表現にマッチした箇所を文字列replaceStringに置換したものを返す。
// replaceString中で使用できるエスケープシーケンスはOGReplaceExpression.hを参照。
// 最初にマッチした部分のみを置換
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOptions)searchOptions;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString
	withString:(NSString*)replaceString 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOptions)searchOptions;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

// 全てのマッチした部分を置換
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOptions)searchOptions;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString
	withString:(NSString*)replaceString 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOptions)searchOptions;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

// マッチした部分を置換
/*
 isReplaceAll == YES ならば全てのマッチした部分を置換
				 NO  ならば最初にマッチした部分のみを置換
 count: 置換した数
 */
- (NSString*)replaceString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;

- (NSString*)replaceString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

- (id<OGStringProtocol>)replaceOGString:(id<OGStringProtocol>)targetString 
	withOGString:(id<OGStringProtocol>)replaceString 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

// デリゲートに処理を委ねた置換
/*
 aSelectorは次の形式でなければならない
 引数:
	1番目: マッチしたOGRegularExpressionMatchオブジェクト
	2番目: contextInfo:で渡したcontextInfo
 戻り値:
	置換した文字列
	(ただし、nilを返した場合はそこで置換を中止する。)
	
 例: 摂氏を華氏に変換する。
	- (NSString*)fahrenheitForCelsius:(OGRegularExpressionMatch*)aMatch contextInfo:(id)contextInfo
	{
		double	celcius = [[aMatch substringAtIndex:1] doubleValue];
		double	fahrenheit = celcius * 9.0 / 5.0 + 32.0;
		return [NSString stringWithFormat:@"%.1fF", fahrenheit];
	}
 */
// 最初にマッチした部分のみを置換
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

- (id<OGStringProtocol>)replaceFirstMatchInOGString:(id<OGStringProtocol>)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

// 全てのマッチした部分を置換
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

- (id<OGStringProtocol>)replaceAllMatchesInOGString:(id<OGStringProtocol>)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange;

// マッチした部分を置換
/*
 isReplaceAll == YES ならば全てのマッチした部分を置換
				 NO  ならば最初にマッチした部分のみを置換
 count: 置換した数
 */
- (NSString*)replaceString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;
- (NSString*)replaceString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;	
- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

- (id<OGStringProtocol>)replaceOGString:(id<OGStringProtocol>)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOptions)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;


/*********
 * Split *
 *********/
// マッチした部分で文字列を分割し、NSArrayに収めて返す。
- (NSArray*)splitString:(NSString*)aString;

- (NSArray*)splitString:(NSString*)aString 
	options:(OgreOptions)searchOptions;
	
- (NSArray*)splitString:(NSString*)aString 
	options:(OgreOptions)searchOptions
	range:(NSRange)searchRange;
	
/*
 分割数limitの意味 (例は@","にマッチさせた場合のもの)
	limit >  0:				最大でlimit個の単語に分割する。limit==3のとき、@"a,b,c,d,e" -> (@"a", @"b", @"c")
	limit == 0(デフォルト):	最後が空文字列のときは無視する。@"a,b,c," -> (@"a", @"b", @"c")
	limit <  0:				最後が空文字列でも含める。@"a,b,c," -> (@"a", @"b", @"c", @"")
 */
- (NSArray*)splitString:(NSString*)aString 
	options:(OgreOptions)searchOptions
	range:(NSRange)searchRange
	limit:(int)limit;


/*************
 * Utilities *
 *************/
// OgreSyntaxとintの相互変換
+ (int)intValueForSyntax:(OgreSyntax)syntax;
+ (OgreSyntax)syntaxForIntValue:(int)intValue;
// OgreSyntaxを表す文字列
+ (NSString*)stringForSyntax:(OgreSyntax)syntax;
// Optionsを表す文字列配列
+ (NSArray*)stringsForOptions:(OgreOptions)options;

// 文字列を正規表現で安全な文字列に変換する。(@"|().?*+{}^$[]-&#:=!<>@\\"を退避する)
+ (NSString*)regularizeString:(NSString*)string;

// 改行コードが何か調べる
+ (OgreNewlineCharacter)newlineCharacterInString:(NSString*)aString;
// 改行コードをnewlineCharacterに統一する。
+ (NSString*)replaceNewlineCharactersInString:(NSString*)aString withCharacter:(OgreNewlineCharacter)newlineCharacter;
// 改行コードを取り除く
+ (NSString*)chomp:(NSString*)aString;

@end
