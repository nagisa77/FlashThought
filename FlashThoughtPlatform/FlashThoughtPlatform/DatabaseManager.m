//
//  DatabaseManager.m
//  FlashThought
//
//  Created by tim on 2024/4/4.
//

#import "DatabaseManager.h"
#import <Firebase/Firebase.h>
#import <FlashThoughtPlatform/LogManager.h>

#define APP_LOCAL_DATABASE_KEY @"FlashThoughts"

@interface DatabaseManager ()
@end

@implementation DatabaseManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
  static DatabaseManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  return self;
}

#pragma mark - Public Methods

- (void)observeUserBase64DataWithCompletion:(void (^)(NSData *data))completion {
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    NSString *uid = user.uid;
    FIRDatabaseReference *userRef =
        [[[[FIRDatabase database] reference] child:@"user_data"] child:uid];
    [userRef observeEventType:FIRDataEventTypeValue
                    withBlock:^(FIRDataSnapshot *_Nonnull snapshot) {
                      [self parseAllThoughtDataWithDataSnapshot:snapshot
                                      completion:completion];
                    }];
  }
}

- (void)observeUserAPIKeyCompletion:(void (^)(NSString *apikey))completion {
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    NSString *uid = user.uid;
    FIRDatabaseReference *userRef =
        [[[[FIRDatabase database] reference] child:@"user_data"] child:uid];
    [userRef observeEventType:FIRDataEventTypeValue
                    withBlock:^(FIRDataSnapshot *_Nonnull snapshot) {
                      [self parseAPIKeyWithDataSnapshot:snapshot
                                      completion:completion];
                    }];
  }
}

- (void)observeUserHostWithCompletion:(void (^)(NSString *host))completion {
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    NSString *uid = user.uid;
    FIRDatabaseReference *userRef =
        [[[[FIRDatabase database] reference] child:@"user_data"] child:uid];
    [userRef observeEventType:FIRDataEventTypeValue
                    withBlock:^(FIRDataSnapshot *_Nonnull snapshot) {
                      [self parseHostWithDataSnapshot:snapshot
                                      completion:completion];
                    }];
  }
}

- (void)parseAPIKeyWithDataSnapshot:(FIRDataSnapshot *_Nonnull)snapshot
                  completion:(void (^)(NSString *apiKey))completion {
  // 检查数据快照是否存在
  if (snapshot.exists) {
    // 尝试从快照中获取数据字典
    NSDictionary *value = snapshot.value;
    NSString *apiKey = value[@"apikey"];
    if (apiKey) {
      completion(apiKey);
    } else {
      // 如果数据字符串不存在，返回空NSData对象
      completion(@"");
    }
  } else {
    // 如果快照不存在数据，返回空NSData对象
    completion(@"");
  }
}

- (void)parseHostWithDataSnapshot:(FIRDataSnapshot *_Nonnull)snapshot
                  completion:(void (^)(NSString *host))completion {
  // 检查数据快照是否存在
  if (snapshot.exists) {
    // 尝试从快照中获取数据字典
    NSDictionary *value = snapshot.value;
    NSString *apiKey = value[@"host"];
    if (apiKey) {
      completion(apiKey);
    } else {
      // 如果数据字符串不存在，返回空NSData对象
      completion(@"");
    }
  } else {
    // 如果快照不存在数据，返回空NSData对象
    completion(@"");
  }
}

- (void)parseAllThoughtDataWithDataSnapshot:(FIRDataSnapshot *_Nonnull)snapshot
                  completion:(void (^)(NSData *data))completion {
  // 检查数据快照是否存在
  if (snapshot.exists) {
    // 尝试从快照中获取数据字典
    NSDictionary *value = snapshot.value;
    NSString *dataString = value[@"data"];
    if (dataString) {
      // 将Base64字符串解码为NSData
      NSData *data = [[NSData alloc] initWithBase64EncodedString:dataString
                                                         options:0];
      completion(data);
    } else {
      // 如果数据字符串不存在，返回空NSData对象
      completion([NSData data]);
    }
  } else {
    // 如果快照不存在数据，返回空NSData对象
    completion([NSData data]);
  }
}

- (void)loadAllDataWithCompletion:(void (^)(NSData *data))completion {
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    // 获取当前用户的UID
    NSString *uid = user.uid;
    // 获取指向用户数据的数据库引用
    FIRDatabaseReference *ref =
        [[[[FIRDatabase database] reference] child:@"user_data"] child:uid];

    // 监听单次事件
    [ref observeSingleEventOfType:FIRDataEventTypeValue
        withBlock:^(FIRDataSnapshot *_Nonnull snapshot) {
          [self parseAllThoughtDataWithDataSnapshot:snapshot completion:completion];
        }
        withCancelBlock:^(NSError *_Nonnull error) {
          // 错误处理，返回空NSData对象
          FLog(@"Error fetching data: %@", error.localizedDescription);
          completion([NSData data]);
        }];
  } else {
    NSUserDefaults *sharedDefaults =
        [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME];
    NSData *storedData = [sharedDefaults objectForKey:APP_LOCAL_DATABASE_KEY];
    completion(storedData);
  }
}

- (void)loadHostWithCompletion:(void (^)(NSString *host))completion {
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    // 获取当前用户的UID
    NSString *uid = user.uid;
    // 获取指向用户数据的数据库引用
    FIRDatabaseReference *ref =
        [[[[FIRDatabase database] reference]
          child:@"user_data"]
          child:uid];

    // 监听单次事件
    [ref observeSingleEventOfType:FIRDataEventTypeValue
        withBlock:^(FIRDataSnapshot *_Nonnull snapshot) {
      [self parseHostWithDataSnapshot:snapshot completion:completion];
    }
        withCancelBlock:^(NSError *_Nonnull error) {
          FLog(@"Error fetching data: %@", error.localizedDescription);
          completion(@"");
        }];
  } else {
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME];
    NSString *retrievedOpenaiKey = [defaults stringForKey:@"proxy"];
    
    completion(retrievedOpenaiKey);
  }
}

- (void)loadAPIKeyWithCompletion:(void (^)(NSString *apiKey))completion {
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    // 获取当前用户的UID
    NSString *uid = user.uid;
    // 获取指向用户数据的数据库引用
    FIRDatabaseReference *ref =
        [[[[FIRDatabase database] reference]
          child:@"user_data"]
          child:uid];

    // 监听单次事件
    [ref observeSingleEventOfType:FIRDataEventTypeValue
        withBlock:^(FIRDataSnapshot *_Nonnull snapshot) {
      [self parseAPIKeyWithDataSnapshot:snapshot completion:completion];
    }
        withCancelBlock:^(NSError *_Nonnull error) {
          FLog(@"Error fetching data: %@", error.localizedDescription);
          completion(@"");
        }];
  } else {
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME];
    NSString *retrievedOpenaiKey = [defaults stringForKey:@"openaiKey"];
    
    completion(retrievedOpenaiKey);
  }
}

- (void)saveData:(NSData *)data {
  // 确保用户已经登录
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    // 获取用户的UID
    NSString *uid = user.uid;

    // 将NSData转换为Base64字符串
    NSString *dataString = [data base64EncodedStringWithOptions:0];

    // 创建一个指向Firebase数据库的引用
    FIRDatabaseReference *ref = [[FIRDatabase database] reference];

    // 将数据保存到数据库的指定位置
    // 这里我们存储在"user_data"节点下，你可以根据需要调整路径
    [[[ref child:@"user_data"] child:uid] setValue:@{@"data" : dataString}];
  } else {
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME];
    [defaults setObject:data forKey:APP_LOCAL_DATABASE_KEY];
    [defaults synchronize];
  }
}

- (void)saveAPIKey:(NSString *)apiKey {
  // 确保用户已经登录
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    NSString *uid = user.uid;
    FIRDatabaseReference *ref = [[FIRDatabase database] reference];
    [[[ref child:@"user_data"] child:uid] setValue:@{@"apikey" : apiKey}];
  } else {
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME];
    [defaults setObject:apiKey forKey:@"openaiKey"];
    [defaults synchronize];
  }
}

- (void)saveHost:(NSString *)host {
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    NSString *uid = user.uid;
    FIRDatabaseReference *ref = [[FIRDatabase database] reference];
    [[[ref child:@"user_data"] child:uid] setValue:@{@"host" : host}];
  } else {
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME];
    [defaults setObject:host forKey:@"proxy"];
    [defaults synchronize];
  }
}

@end
