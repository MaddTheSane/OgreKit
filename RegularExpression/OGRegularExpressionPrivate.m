/*
 * Name: OGRegularExpressionPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 01 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#ifndef NOT_RUBY
# define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
# define HAVE_CONFIG_H
#endif
#import <OgreKit/onigmo.h>

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OGMutableString.h>


OnigSyntaxType  OgrePrivatePOSIXBasicSyntax;
OnigSyntaxType  OgrePrivatePOSIXExtendedSyntax;
OnigSyntaxType  OgrePrivateEmacsSyntax;
OnigSyntaxType  OgrePrivateGrepSyntax;
OnigSyntaxType  OgrePrivateGNURegexSyntax;
OnigSyntaxType  OgrePrivateJavaSyntax;
OnigSyntaxType  OgrePrivatePerlSyntax;
OnigSyntaxType  OgrePrivateRubySyntax;
