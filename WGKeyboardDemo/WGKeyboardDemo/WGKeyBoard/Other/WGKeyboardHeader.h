//
//  WGKeyboardHeader.h
//  Keyboard
//
//  Created by Veeco on 2019/5/22.
//  Copyright © 2019 Chance. All rights reserved.
//

#ifndef WGKeyboardHeader_h
#define WGKeyboardHeader_h

// 表情控件高度
#define KeyboardStikerViewHeight (230 + BOTTOM_SAFE_MARGIN)
// 更多控件高度
#define KeyboardMoreViewHeight KeyboardStikerViewHeight
// 更多控件页码Y
#define KeyboardMoreViewPageControlY 210
// 页码高度
#define KeyboardPageControlHeight 20
// 封面控件高度
#define KeyboardStikerCoverViewHeight 40
// 封面Y
#define StikerCoverViewY (KeyboardStikerViewHeight - BOTTOM_SAFE_MARGIN - KeyboardStikerCoverViewHeight)
// 表情滚动容器高度
#define StikerContentViewHeight (StikerCoverViewY - KeyboardPageControlHeight)

#endif /* WGKeyboardHeader_h */
