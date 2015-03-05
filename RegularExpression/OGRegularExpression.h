/*
 * Name: OGRegularExpression.h
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
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
#import <OgreKit/oniguruma.h>

//#define DEBUG_OGRE

/* constants */
// version string
#define OgreVersionString	@"2.1.4"

// compile time options:

// OgreOption is a bit field.
typedef unsigned int OgreOption;
extern const OgreOption	OgreNoneOption;
extern const OgreOption	OgreSingleLineOption;
extern const OgreOption	OgreMultilineOption;
extern const OgreOption	OgreIgnoreCaseOption;
extern const OgreOption	OgreExtendOption;
extern const OgreOption	OgreFindLongestOption;
extern const OgreOption	OgreFindNotEmptyOption;
extern const OgreOption	OgreNegateSingleLineOption;
extern const OgreOption	OgreDontCaptureGroupOption;
extern const OgreOption	OgreCaptureGroupOption;
// (REG_OPTION_POSIX_REGION is not used) ((REG_OPTION_POSIX_REGIONは使用しない))
// OgreDelimitByWhitespaceOption when using the OgreSimpleMatchingSyntax, whether whitespace regarded as a separator of words (OgreDelimitByWhitespaceOptionはOgreSimpleMatchingSyntaxの使用時に、空白文字を単語の区切りとみなすかどうか)
// Example: @ "AAA BBB CCC" -> @ "(AAA) | (BBB) | (CCC)" (例: @"AAA BBB CCC" -> @"(AAA)|(BBB)|(CCC)")
extern const OgreOption	OgreDelimitByWhitespaceOption;

#define OgreCompileTimeOptionMask(x)	((x) & (OgreSingleLineOption | OgreMultilineOption | OgreIgnoreCaseOption | OgreExtendOption | OgreFindLongestOption | OgreFindNotEmptyOption | OgreNegateSingleLineOption | OgreDontCaptureGroupOption | OgreCaptureGroupOption | OgreDelimitByWhitespaceOption))

// search time options:
extern const OgreOption	OgreNotBOLOption;
extern const OgreOption	OgreNotEOLOption;
extern const OgreOption	OgreFindEmptyOption;

#define OgreSearchTimeOptionMask(x)		((x) & (OgreNotBOLOption | OgreNotEOLOption | OgreFindEmptyOption))

// replace time options:
extern const OgreOption	OgreReplaceWithAttributesOption;
extern const OgreOption	OgreReplaceFontsOption;
extern const OgreOption	OgreMergeAttributesOption;

#define OgreReplaceTimeOptionMask(x)		((x) & (OgreReplaceWithAttributesOption | OgreReplaceFontsOption | OgreMergeAttributesOption))

// compile time syntax
typedef NS_ENUM(NSInteger, OgreSyntax) {
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
// In GUI ¥ mark (GUI中の￥マーク)
#define	OgreGUIYenCharacter				@"\u00A5"

// newline character
typedef NS_ENUM(NSInteger, OgreNewlineCharacter) {
	OgreNonbreakingNewlineCharacter = -1, 
	OgreUnixNewlineCharacter = 0,		OgreLfNewlineCharacter = 0, 
	OgreMacNewlineCharacter = 1,		OgreCrNewlineCharacter = 1, 
	OgreWindowsNewlineCharacter = 2,	OgreCrLfNewlineCharacter = 2, 
	OgreUnicodeLineSeparatorNewlineCharacter,
	OgreUnicodeParagraphSeparatorNewlineCharacter
};


// exception name
extern NSString	* const OgreException;

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator;
@protocol OGStringProtocol;

@interface OGRegularExpression : NSObject <NSCopying, NSCoding>
{
    NSString			*_escapeCharacter;				// \ Alternate character (\の代替文字)
    NSString			*_expressionString;				// A string that represents the regular expression (正規表現を表す文字列)
    unichar             *_UTF16ExpressionString;        // UTF16 string that represents the regular expression (正規表現を表すUTF16文字列)
    OgreOption			_options;						// Compile option (コンパイルオプション)
    OgreSyntax			_syntax;						// Regular expression syntax (正規表現の構文)
	
	NSMutableDictionary	*_groupIndexForNameDictionary;	// dictionary-catching index by name (nameでindexを引く辞書)
														// Structure: / (? <a> A +) (? <B> b +) (? <a> C +) / => {"a" = (1,3), "b" = (2)} (構造: /(?<a>a+)(?<b>b+)(?<a>c+)/ => {"a" = (1,3), "b" = (2)})
	NSMutableArray		*_nameForGroupIndexArray;		// Reverse dictionary-catching name (index-1) (SEQ) ((index-1)でnameを引く逆引き辞書(配列))
														// Structure: / (? <a> A +) (? <B> b +) (? <a> C +) / => ("a", "b", "a") (構造: /(?<a>a+)(?<b>b+)(?<a>c+)/ => ("a", "b", "a"))
	regex_t				*_regexBuffer;					// Oniguruma regular expression structure (鬼車正規表現構造体)
}

/****************************
 * creation, initialization *
 ****************************/
//  Arguments:
//   expressionString: character string that represents the regular expression (expressionString: 正規表現を表す文字列)
//   options: options (see below) (options: オプション(後述参照))
//   syntax: Syntax (see below) (syntax: 構文(後述参照))
//   escapeCharacter: \ alternate character (escapeCharacter: \の代替文字)
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
	options:(OgreOption)options;
+ (instancetype)regularExpressionWithString:(NSString*)expressionString
	options:(OgreOption)options
	syntax:(OgreSyntax)syntax
	escapeCharacter:(NSString*)character;
	
- (instancetype)initWithString:(NSString*)expressionString;
- (instancetype)initWithString:(NSString*)expressionString
	options:(OgreOption)options;
- (instancetype)initWithString:(NSString*)expressionString 
	options:(OgreOption)options
	syntax:(OgreSyntax)syntax
	escapeCharacter:(NSString*)character NS_DESIGNATED_INITIALIZER;


/*************
 * accessors *
 *************/
// And return copy the string that represents the regular expression. Need recompile To change. (正規表現を表している文字列をコピーして返す。変更するにはrecompileが必要。)
@property (nonatomic, readonly, copy) NSString *expressionString;
// Valid options currently. Need recompile To change. (現在有効なオプション。変更するにはrecompileが必要。)
@property (nonatomic, readonly) OgreOption options;
// Regular expression syntax you are currently using. Need recompile To change. (現在使用している正規表現の構文。変更するにはrecompileが必要。)
@property (nonatomic, readonly) OgreSyntax syntax;
// Escape character @ alternative character of "\\". Need recompile To change. Will be a few percent slower when you change. (エスケープ文字 @"\\" の代替文字。変更するにはrecompileが必要。変更すると数割遅くなります。)
@property (nonatomic, readonly, copy) NSString *escapeCharacter;

// number of capture group (capture groupの数)
@property (nonatomic, readonly) NSUInteger numberOfGroups;
// number of named group (named groupの数)
@property (nonatomic, readonly) NSUInteger numberOfNames;
// array of name (nameの配列)
// Returns nil if you are not using the named group. (named groupを使用していない場合はnilを返す。)
@property (nonatomic, readonly, copy) NSArray *names;

// Current default escape character. The initial value @ "\\" (\ symbols in the GUI) (現在のデフォルトのエスケープ文字。初期値は @"\\"(GUI中の\記号))
+ (NSString*)defaultEscapeCharacter;
// I want to change the default escape character. Will be a few percent slower when you change. (デフォルトのエスケープ文字を変更する。変更すると数割遅くなります。)
// It does not affect the instance that was created prior to the change. (変更前に作成されたインスタンスには影響を与えない。)
// I raise an exception in the case of characters that character can not be used. (character が使用できない文字の場合には例外を発生する。)
+ (void)setDefaultEscapeCharacter:(NSString*)character;

// Current default regular expression syntax. The initial value OgreRubySyntax (// 現在のデフォルトの正規表現構文。初期値は OgreRubySyntax)
+ (OgreSyntax)defaultSyntax;
// I want to change the default regular expression syntax. (デフォルトの正規表現構文を変更する。)
// It does not affect the instance that was created prior to the change. (変更前に作成されたインスタンスには影響を与えない。)
+ (void)setDefaultSyntax:(OgreSyntax)syntax;

// I return the version string of OgreKit (OgreKitのバージョン文字列を返す)
+ (NSString*)version;
// I return the version string of oniguruma (onigurumaのバージョン文字列を返す)
+ (NSString*)onigurumaVersion;

// description
@property (nonatomic, readonly, copy) NSString *description;


/*******************
 * Validation test *
 *******************/
// If correct YES, it returns if there is no correctly NO. (正しければ YES、正しくなければ NO を返す。)
/* 正しくない理由を知りたい場合は、次のようにして例外を拾って下さい。
	@try {
		OGRegularExpression	*rx = [OGRegularExpression regularExpressionWithString:expressionString];
	} @catch (NSException *localException) {
		// Exception handling (例外処理)
		NSLog(@"%@ caught\n", [localException name]);
		NSLog(@"reason = \"%@\"\n", [localException reason]);
	}
 */
+ (BOOL)isValidExpressionString:(NSString*)expressionString;
+ (BOOL)isValidExpressionString:(NSString*)expressionString
	options:(OgreOption)options;
+ (BOOL)isValidExpressionString:(NSString*)expressionString 
	options:(OgreOption)options
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
// I return the OGRegularExpressionMatch object of the first matching part. (最初にマッチした部分の OGRegularExpressionMatch オブジェクトを返す。)
// Returns nil if you do not match. (マッチしなかった場合は nil を返す。)
- (OGRegularExpressionMatch*)matchInString:(NSString*)string;
- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	range:(NSRange)range;
- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	options:(OgreOption)options;
- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	options:(OgreOption)options
	range:(NSRange)searchRange;

- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString;
- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString 
	range:(NSRange)range;
- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString 
	options:(OgreOption)options;
- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString 
	options:(OgreOption)options
	range:(NSRange)searchRange;

- (OGRegularExpressionMatch*)matchInOGString:(id<OGStringProtocol>)string 
	options:(OgreOption)options 
	range:(NSRange)searchRange;

// The OGRegularExpressionMatch object of all of the matched substring (全てのマッチした部分の OGRegularExpressionMatch オブジェクトを)
// I return to enumerate OGRegularExpressionEnumerator object. (列挙する OGRegularExpressionEnumerator オブジェクトを返す。)
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string;
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string 
	options:(OgreOption)options;
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string 
	range:(NSRange)searchRange;
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string 
	options:(OgreOption)options
	range:(NSRange)searchRange;
	
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString;
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString 
	options:(OgreOption)options;
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString 
	range:(NSRange)searchRange;
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString 
	options:(OgreOption)options
	range:(NSRange)searchRange;

- (NSEnumerator*)matchEnumeratorInOGString:(id<OGStringProtocol>)string 
	options:(OgreOption)options
	range:(NSRange)searchRange;
	
// The OGRegularExpressionMatch object of all of the matched substring (全てのマッチした部分の OGRegularExpressionMatch オブジェクトを)
// I return the NSArray object with the elements. Order is matched order. (要素に持つ NSArray オブジェクトを返す。順序はマッチした順。)
// ([[Self matchEnumeratorInString: string] allObject] and the same) (([[self matchEnumeratorInString:string] allObject]と同じ))
// Returns nil if you do not match. (マッチしなかった場合は nil を返す。)
- (NSArray*)allMatchesInString:(NSString*)string;
- (NSArray*)allMatchesInString:(NSString*)string
	options:(OgreOption)options;
- (NSArray*)allMatchesInString:(NSString*)string
	range:(NSRange)searchRange;
- (NSArray*)allMatchesInString:(NSString*)string
	options:(OgreOption)options
	range:(NSRange)searchRange;

- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString;
- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString
	options:(OgreOption)options;
- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString
	range:(NSRange)searchRange;
- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString
	options:(OgreOption)options
	range:(NSRange)searchRange;

- (NSArray*)allMatchesInOGString:(id<OGStringProtocol>)string
	options:(OgreOption)options
	range:(NSRange)searchRange;


/***********
 * Replace *
 ***********/
// A place that matches the regular expression in a string targetString I return what was replaced by string replaceString. (文字列targetString中の正規表現にマッチした箇所を文字列replaceStringに置換したものを返す。)
// See the escape sequence OGReplaceExpression.h that can be used in replaceString. (replaceString中で使用できるエスケープシーケンスはOGReplaceExpression.hを参照。)
// First matching portion only the replacement (最初にマッチした部分のみを置換)
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOption)searchOptions;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOption)searchOptions;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

// Replace all of the matched substring (全てのマッチした部分を置換)
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOption)searchOptions;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOption)searchOptions;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

// Replace matched substring (マッチした部分を置換)
/*
 isReplaceAll == YES ならば全てのマッチした部分を置換
				 NO  ならば最初にマッチした部分のみを置換
 count: 置換した数
 */
- (NSString*)replaceString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;

- (NSString*)replaceString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(NSUInteger*)numberOfReplacement;

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(NSUInteger*)numberOfReplacement;

- (id<OGStringProtocol>)replaceOGString:(id<OGStringProtocol>)targetString
	withOGString:(id<OGStringProtocol>)replaceString 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(NSUInteger*)numberOfReplacement;

// Substitution was entrusted with processing to delegate (デリゲートに処理を委ねた置換)
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
// First matching portion only the replacement (最初にマッチした部分のみを置換)
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

- (id<OGStringProtocol>)replaceFirstMatchInOGString:(id<OGStringProtocol>)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

// Replace all of the matched substring (全てのマッチした部分を置換)
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

- (id<OGStringProtocol>)replaceAllMatchesInOGString:(id<OGStringProtocol>)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange;

// Replace matched substring (マッチした部分を置換)
/*
 isReplaceAll == YES ならば全てのマッチした部分を置換
				 NO  ならば最初にマッチした部分のみを置換
 count: 置換した数
 */
- (NSString*)replaceString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;
- (NSString*)replaceString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll
	numberOfReplacement:(NSUInteger*)numberOfReplacement;

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;	
- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll
	numberOfReplacement:(NSUInteger*)numberOfReplacement;

- (id<OGStringProtocol>)replaceOGString:(id<OGStringProtocol>)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(__unsafe_unretained id)contextInfo
	options:(OgreOption)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll
	numberOfReplacement:(NSUInteger*)numberOfReplacement;


/*********
 * Split *
 *********/
// Divides the string matched portions, and return is housed in NSArray. (マッチした部分で文字列を分割し、NSArrayに収めて返す。)
- (NSArray*)splitString:(NSString*)aString;

- (NSArray*)splitString:(NSString*)aString 
	options:(OgreOption)searchOptions;
	
- (NSArray*)splitString:(NSString*)aString 
	options:(OgreOption)searchOptions 
	range:(NSRange)searchRange;
	
/*
 分割数limitの意味 (例は@","にマッチさせた場合のもの)
	limit >  0:				最大でlimit個の単語に分割する。limit==3のとき、@"a,b,c,d,e" -> (@"a", @"b", @"c")
	limit == 0(デフォルト):	最後が空文字列のときは無視する。@"a,b,c," -> (@"a", @"b", @"c")
	limit <  0:				最後が空文字列でも含める。@"a,b,c," -> (@"a", @"b", @"c", @"")
 */
- (NSArray*)splitString:(NSString*)aString 
	options:(OgreOption)searchOptions
	range:(NSRange)searchRange
	limit:(NSInteger)limit;


/*************
 * Utilities *
 *************/
// Interconversion of OgreSyntax and int (OgreSyntaxとintの相互変換)
+ (NSInteger)intValueForSyntax:(OgreSyntax)syntax;
+ (OgreSyntax)syntaxForIntValue:(int)intValue;
// A string representing the OgreSyntax (OgreSyntaxを表す文字列)
+ (NSString*)stringForSyntax:(OgreSyntax)syntax;
// String array that represents the Options (Optionsを表す文字列配列)
+ (NSArray*)stringsForOptions:(OgreOption)options;

// The string I want to convert to a safe string in the regular expression. (@ "|.?! () * + {} ^ $ [] - & #: = <> @ \\" I saved) (文字列を正規表現で安全な文字列に変換する。(@"|().?*+{}^$[]-&#:=!<>@\\"を退避する))
+ (NSString*)regularizeString:(NSString*)string;

// Examine new line code is something (改行コードが何か調べる)
+ (OgreNewlineCharacter)newlineCharacterInString:(NSString*)aString;
// A newline code I unify in newlineCharacter. (改行コードをnewlineCharacterに統一する。)
+ (NSString*)replaceNewlineCharactersInString:(NSString*)aString withCharacter:(OgreNewlineCharacter)newlineCharacter;
// I remove the line break code (改行コードを取り除く)
+ (NSString*)chomp:(NSString*)aString;

@end
