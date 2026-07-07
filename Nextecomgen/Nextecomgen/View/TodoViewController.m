//
//  TodoViewController.m
//  Nextecomgen
//
//  Created by Harshith on 07/07/26.
//

#import "TodoViewController.h"
#import "TodoItem.h"


@interface TodoViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSMutableArray *todos;

@end



@implementation TodoViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Tasks List";
    self.view.backgroundColor =
    UIColor.systemBackgroundColor;
    
    
    UIBarButtonItem *backButton =
    [[UIBarButtonItem alloc]
     initWithImage:[UIImage systemImageNamed:@"chevron.left"]
     style:UIBarButtonItemStylePlain
     target:self
     action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    
    UIBarButtonItem *addButton =
    [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
     target:self
     action:@selector(addTodo)];
    
    
    self.navigationItem.rightBarButtonItem = addButton;
    
    
    
    self.todos =
    [NSMutableArray array];
    
    
    [self loadTodos];
    
    
    [self setupUI];
    
}


-(void)goBack {
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
    
}



-(void)setupUI {
    
    
    self.tableView =
    [[UITableView alloc]
     initWithFrame:CGRectZero
     style:UITableViewStyleInsetGrouped];
    
    
    self.tableView.delegate = self;
    
    self.tableView.dataSource = self;
    
    
    
    [self.view addSubview:self.tableView];
    
    
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    
    [NSLayoutConstraint activateConstraints:@[
        
        
        [self.tableView.topAnchor
         constraintEqualToAnchor:self.view.topAnchor],
        
        
        [self.tableView.bottomAnchor
         constraintEqualToAnchor:self.view.bottomAnchor],
        
        
        [self.tableView.leadingAnchor
         constraintEqualToAnchor:self.view.leadingAnchor],
        
        
        [self.tableView.trailingAnchor
         constraintEqualToAnchor:self.view.trailingAnchor]
        
        
    ]];
    
    
}




-(NSInteger)tableView:(UITableView *)tableView
numberOfRowsInSection:(NSInteger)section {
    
    return self.todos.count;
    
}



-(UITableViewCell *)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    UITableViewCell *cell =
    [[UITableViewCell alloc]
     initWithStyle:UITableViewCellStyleDefault
     reuseIdentifier:@"TodoCell"];
    
    
    
    TodoItem *item =
    self.todos[indexPath.row];
    
    
    
    cell.textLabel.text =
    item.title;
    
    
    
    if(item.completed) {
        
        
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.tintColor = [UIColor greenColor];
        cell.textLabel.textColor =
        UIColor.greenColor;
        
        
    }
    else {
        
        
        cell.accessoryType =
        UITableViewCellAccessoryNone;
        
        
        cell.textLabel.textColor =
        UIColor.labelColor;
        
    }
    
    
    
    return cell;
    
}



-(void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    TodoItem *item =
    self.todos[indexPath.row];
    
    
    item.completed =
    !item.completed;
    
    
    
    [self saveTodos];
    
    
    
    [tableView reloadRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
    
}



-(BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
    
}



-(UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    UIContextualAction *deleteAction =
    [UIContextualAction
     contextualActionWithStyle:UIContextualActionStyleDestructive
     title:@"Delete"
     handler:^(UIContextualAction *action,
               UIView *view,
               void (^completionHandler)(BOOL)) {
        
        
        
        [self.todos removeObjectAtIndex:indexPath.row];
        
        
        [self saveTodos];
        
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        
        
        completionHandler(YES);
        
    }];
    
    
    
    
    UIContextualAction *editAction =
    [UIContextualAction
     contextualActionWithStyle:UIContextualActionStyleNormal
     title:@"Edit"
     handler:^(UIContextualAction *action,
               UIView *view,
               void (^completionHandler)(BOOL)) {
        
        
        
        [self editTodoAtIndex:indexPath.row];
        
        
        completionHandler(YES);
        
    }];
    
    
    
    editAction.backgroundColor =
    UIColor.systemOrangeColor;
    
    
    
    return
    [UISwipeActionsConfiguration
     configurationWithActions:@[
        deleteAction,
        editAction
    ]];
    
}


-(void)addTodo {
    
    
    UIAlertController *alert =
    [UIAlertController
     alertControllerWithTitle:@"New Task"
     message:nil
     preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    [alert addTextFieldWithConfigurationHandler:nil];
    
    
    
    UIAlertAction *save =
    [UIAlertAction
     actionWithTitle:@"Add"
     style:UIAlertActionStyleDefault
     handler:^(UIAlertAction *action) {
        
        
        
        UITextField *field =
        alert.textFields.firstObject;
        
        
        
        if(field.text.length > 0) {
            
            
            TodoItem *item =
            [TodoItem new];
            
            
            item.todoId =
            NSUUID.UUID.UUIDString;
            
            
            item.title =
            field.text;
            
            
            item.completed =
            NO;
            
            
            
            [self.todos addObject:item];
            [self saveTodos];
            [self.tableView reloadData];
            
        }
        
        
    }];
    
    
    
    UIAlertAction *cancel =
    [UIAlertAction
     actionWithTitle:@"Cancel"
     style:UIAlertActionStyleCancel
     handler:nil];
    
    
    
    [alert addAction:save];
    
    [alert addAction:cancel];
    
    
    
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
}




-(void)editTodoAtIndex:(NSInteger)index {
    
    
    TodoItem *item =
    self.todos[index];
    
    
    
    UIAlertController *alert =
    [UIAlertController
     alertControllerWithTitle:@"Edit Task"
     message:nil
     preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        
        textField.text =
        item.title;
        
        
    }];
    
    
    
    UIAlertAction *save =
    [UIAlertAction
     actionWithTitle:@"Save"
     style:UIAlertActionStyleDefault
     handler:^(UIAlertAction *action) {
        
        
        
        UITextField *field =
        alert.textFields.firstObject;
        
        
        
        if(field.text.length > 0) {
            
            
            item.title =
            field.text;
            
            
            
            [self saveTodos];
            
            
            [self.tableView reloadData];
            
        }
        
        
    }];
    
    
    
    UIAlertAction *cancel =
    [UIAlertAction
     actionWithTitle:@"Cancel"
     style:UIAlertActionStyleCancel
     handler:nil];
    
    
    
    [alert addAction:save];
    
    [alert addAction:cancel];
    
    
    
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
}




-(void)saveTodos {
    
    
    NSData *data =
    [NSKeyedArchiver
     archivedDataWithRootObject:self.todos
     requiringSecureCoding:YES
     error:nil];
    
    
    
    [[NSUserDefaults standardUserDefaults]
     setObject:data
     forKey:@"todos"];
    
}



-(void)loadTodos {
    
    
    NSData *data =
    [[NSUserDefaults standardUserDefaults]
     objectForKey:@"todos"];
    
    
    
    if(data) {
        
        
        NSSet *classes =
        [NSSet setWithObjects:
         NSArray.class,
         TodoItem.class,
         NSString.class,
         nil];
        
                
        NSArray *array =
        [NSKeyedUnarchiver
         unarchivedObjectOfClasses:classes
         fromData:data
         error:nil];
        
        if(array) {
            
            self.todos =
            [array mutableCopy];
            
        }
        
    }
    
}
@end
