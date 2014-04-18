//
//  Created by matt on 3/12/12.
//

#import "MGBoxProvider.h"
#import "MGLayoutBox.h"

@implementation MGBoxProvider {
  NSMutableSet *boxCache;
  NSMutableArray *boxPositions;
  NSMutableIndexSet *visibleIndexes;
}

- (id)init {
  self = [super init];
  boxCache = NSMutableSet.set;
  boxPositions = @[].mutableCopy;
  visibleIndexes = NSMutableIndexSet.indexSet;
  return self;
}

+ (instancetype)provider {
  return [[self alloc] init];
}

- (void)reset {
  [boxCache removeAllObjects];
  [visibleIndexes removeAllIndexes];
  [self.container.boxes removeAllObjects];
}

#pragma mark - Box visibility

- (void)updateVisibleIndexes {
    CGRect viewport = self.container.bufferedViewport;
    for (int i = 0; i < self.count; i++) {
        CGRect frame = [self footprintForBoxAtIndex:i];
        BOOL visible = CGRectIntersectsRect(frame, viewport);
        BOOL have = [visibleIndexes containsIndex:i];
        if (visible && !have) {
            [visibleIndexes addIndex:i];
        }
        if (!visible && have) {
            [visibleIndexes removeIndex:i];
        }
    }

    // prune any indexes beyond the end
    [visibleIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        if (index >= self.count) {
            [visibleIndexes removeIndex:index];
        }
    }];
}

#pragma mark - Boxes in and out

- (void)removeBox:(UIView <MGLayoutBox> *)box {
    NSUInteger index = [self.container.boxes indexOfObject:box];
    if (index != NSNotFound) {
        self.container.boxes[index] = NSNull.null;
        [boxCache addObject:box];
    }
    [box removeFromSuperview];
    if ([box respondsToSelector:@selector(disappeared)]) {
        [box disappeared];
    }
}

- (UIView <MGLayoutBox> *)boxAtIndex:(NSUInteger)index {
    id box = self.container.boxes[index];
    if ([box isKindOfClass:NSNull.class]) {
        if (boxCache.count) {
            box = boxCache.anyObject;
            [boxCache removeObject:box];
        } else {
            box = self.boxMaker();
        }
        self.container.boxes[index] = box;
        self.boxCustomiser(box, index);
    }
    return box;
}

- (NSUInteger)count {
    return self.counter();
}

#pragma mark - Animations

- (void)doAppearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration {
    if (self.appearAnimation) {
        self.appearAnimation(box, index, duration, box.frame, box.frame);
    } else {
        box.alpha = 0;
        [UIView animateWithDuration:duration delay:0
              options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
              animations:^{
                  box.alpha = 1;
              } completion:nil];
    }
}

- (void)doDisappearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration {
    if (self.disappearAnimation) {
        self.disappearAnimation(box, index, duration, box.frame, box.frame);
    } else {
        [UIView animateWithDuration:duration delay:0
              options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
              animations:^{
                  box.alpha = 0;
              } completion:nil];
    }
}

- (void)doMoveAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration fromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame {
    if (self.moveAnimation) {
        self.moveAnimation(box, index, duration, fromFrame, toFrame);
    } else {
        [UIView animateWithDuration:duration delay:0
              options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
              animations:^{
                  box.frame = toFrame;
              } completion:nil];
    }
}

#pragma mark - Frames

- (CGSize)sizeForBoxAtIndex:(NSUInteger)index {
    return self.boxSizer(index);
}

- (CGPoint)originForBoxAtIndex:(NSUInteger)index {
    if (index >= self.boxPositions.count) {
        [self.container layout];
    }
    return [self.boxPositions[index] CGPointValue];
}

- (CGRect)footprintForBoxAtIndex:(NSUInteger)index {
    return (CGRect){[self originForBoxAtIndex:index], [self sizeForBoxAtIndex:index]};
}

- (CGRect)frameForBox:(UIView <MGLayoutBox> *)box {
    NSUInteger index = [self.container.boxes indexOfObject:box];
    CGRect frame = [self footprintForBoxAtIndex:index];
    frame.origin.x += box.leftMargin;
    frame.origin.y += box.topMargin;
    frame.size.width -= (box.leftMargin + box.rightMargin);
    frame.size.height -= (box.topMargin + box.bottomMargin);
    return frame;
}

#pragma mark - Misc

- (NSIndexSet *)visibleIndexes {
  return visibleIndexes;
}

- (NSMutableArray *)boxPositions {
    return boxPositions;
}

@end
