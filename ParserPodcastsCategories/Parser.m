//
//  Parser.m
//

#import "Parser.h"

@implementation Parser


/*
 https://rss.itunes.apple.com/data/countries.json
 
 https://rss.itunes.apple.com/data/media-types.json
 
 https://rss.itunes.apple.com/data/lang/ru-RU/media-types.json
 
 https://rss.itunes.apple.com/data/lang/ru-RU/common.json
 
 http://itunes.apple.com/ru/rss/topaudiopodcasts/limit=300/explicit=true/json
 */

- (void)start
{
    NSArray *categories = [self getCategories];
    //NSLog(@"categories: %@", categories);
    
    NSArray *countries = [self getCountries];
    //NSLog(@"countries: %@", countries);
    
    [self generateLangsFilesForCategories:categories withCountries:countries];
    
    [self generateLangsFilesForCountries:countries];
    
    [self generateFileForCountries:countries];
    
    [self generateFileForCategories:[self getCategories]];
    
    NSLog(@"Finish");
}


- (void)generateFileForCountries:(NSArray *)countries
{
     NSString *filePath = [NSString stringWithFormat:@"%@/Countries.plist", self.getDocumentsPath];
    [countries writeToFile:filePath atomically:YES];
}


- (void)generateFileForCategories:(NSArray *)categories
{
    NSString *filePath = [NSString stringWithFormat:@"%@/Categories.plist", self.getDocumentsPath];
    [categories writeToFile:filePath atomically:YES];
}


- (void)generateLangsFilesForCountries:(NSArray *)countries
{
    //int i=0;
    
    NSMutableDictionary *countriesDictionary = [NSMutableDictionary dictionary];
    for (NSDictionary *country in countries)
    {
        [countriesDictionary setValue:country[@"name"] forKey:country[@"code"]];
    }
    
    for (NSDictionary *country in countries)
    {
        NSString *URLString = [NSString stringWithFormat:@"https://rss.itunes.apple.com/data/lang/%@/common.json", country[@"lang"]];
        
        NSMutableDictionary *categoriesLang = [NSMutableDictionary dictionary];
        
        NSDictionary *countriesLang = [self getJSONByURLString:URLString][@"feed_country"];
        
        for (NSString *key in countriesLang)
        {
            [categoriesLang setValue:countriesLang[key] forKey:countriesDictionary[key]];
        }
        
        [self saveStringFileFromDictionary:categoriesLang lang:country[@"lang"] fileName:@"CountriesLocalizable"];
        
        //i++; if(i==3) break;
    }
}


- (void)generateLangsFilesForCategories:(NSArray *)categories withCountries:(NSArray *)countries
{
    //int i=0;
    
    NSMutableDictionary *categoriesDictionary = [NSMutableDictionary dictionary];
    for (NSDictionary *category in categories)
    {
        [categoriesDictionary setValue:category[@"id"] forKey:category[@"name"]];
    }
    
    for (NSDictionary *country in countries)
    {
        NSString *URLString = [NSString stringWithFormat:@"https://rss.itunes.apple.com/data/lang/%@/media-types.json", country[@"lang"]];
        
        NSMutableDictionary *categoriesLang = [NSMutableDictionary dictionary];
        
        NSDictionary *mediaTypes = [self getJSONByURLString:URLString];
        for (NSString *key in mediaTypes)
        {
            if (categoriesDictionary[key])
            {
                [categoriesLang setValue:mediaTypes[key] forKey:key];
            }
        }
        
        [self saveStringFileFromDictionary:categoriesLang lang:country[@"lang"] fileName:@"CategoriesLocalizable"];
        
        //i++; if(i==5) break;
    }
}


- (void)saveStringFileFromDictionary:(NSDictionary *)dictionary lang:(NSString*)lang fileName:(NSString *)fileName
{
    NSMutableArray *strings = [NSMutableArray array];
    for (NSString *key in dictionary)
    {
        NSString *string = [NSString stringWithFormat:@"\"%@\" = \"%@\";", key, dictionary[key]];
        [strings addObject:string];
    }
    NSString *content = [strings componentsJoinedByString:@"\n"];
    

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *directoryPath = [NSString stringWithFormat:@"%@/Langs/%@.lproj", self.getDocumentsPath, lang];
    
    if(![fileManager fileExistsAtPath:directoryPath isDirectory:nil])
    {
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.strings", directoryPath, fileName];
    NSData *data = [content dataUsingEncoding: NSUTF8StringEncoding];
    [fileManager createFileAtPath: filePath contents: data attributes:nil];
}


- (NSArray *)getCountries
{
    NSString *URLString = [NSString stringWithFormat:@"https://rss.itunes.apple.com/data/lang/%@/common.json", @"en-US"];
    NSDictionary *countriesLangEn = [self getJSONByURLString:URLString][@"feed_country"];
    
    NSArray *countries = (NSArray *)[self getJSONByURLString:@"https://rss.itunes.apple.com/data/countries.json"];
    
    NSMutableArray *newCountries = [NSMutableArray array];
    
    for (NSDictionary *country in countries)
    {
        if(countriesLangEn[country[@"country_code"]])
        {
            [newCountries addObject:@{
                 @"code": country[@"country_code"],
                 @"lang": country[@"language"],
                 @"name": countriesLangEn[country[@"country_code"]]
             }];
        }
    }
    
    return newCountries;
}
 

- (NSArray *)getCategories
{
    NSArray *mediaTypes = (NSArray *)[self getJSONByURLString:@"https://rss.itunes.apple.com/data/media-types.json"];
    
    NSMutableArray *categories = [NSMutableArray array];
    
    for (NSDictionary *mediaType in mediaTypes)
    {
        if ([mediaType[@"store"] isEqualToString:@"podcast"])
        {
            for (NSDictionary *subgenre in mediaType[@"subgenres"])
            {
                [categories addObject:@{
                    @"id": subgenre[@"id"],
                    @"name": subgenre[@"translation_key"]
                 }];
            }
        }
    }
    
    return categories;
}


- (NSString*)getDocumentsPath
{
    NSString *documensPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return documensPath;
}


- (NSDictionary *)getJSONByURLString:(NSString *)URLString
{
    NSLog(@"%@", URLString);
    NSURL *URL = [NSURL URLWithString:URLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}


@end
