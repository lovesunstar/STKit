//
//  STWaveAnalysis.m
//  STKit
//
//  Created by SunJiangting on 13-3-21.
//  Copyright (c) 2013年 sun. All rights reserved.
//

#import "STWaveAnalysis.h"

void calc_freq(SInt16 *dest, SInt16 *src, fft_state *state) {
    float tmp_out[FFT_BUFFER_SIZE];
    int i;
    fft_perform(src, tmp_out, state);
    for (i = 0; i < FFT_BUFFER_SIZE; i++)
        //		dest[i] = ((int)sqrt(tmp_out[i + 1])) >> 8;
        dest[i] = (SInt16)(tmp_out[i] * (2 ^ 16) / ((FFT_BUFFER_SIZE / 2 * 32768) ^ 2));
}

void calc_mono_pcm(SInt16 dest[2][FFT_BUFFER_SIZE], SInt16 src[2][FFT_BUFFER_SIZE], SInt16 nch) {
    SInt16 i;
    SInt16 *d, *sl, *sr;

    if (nch == 1) {
        memcpy(dest[0], src[0], FFT_BUFFER_SIZE * sizeof(SInt16));
    } else {
        d = dest[0];
        sl = src[0];
        sr = src[1];
        for (i = 0; i < FFT_BUFFER_SIZE; i++) {
            *(d++) = (*(sl++) + *(sr++)) >> 1;
        }
    }
}

void calc_stereo_pcm(SInt16 dest[2][FFT_BUFFER_SIZE], SInt16 src[2][FFT_BUFFER_SIZE], SInt16 nch) {
    memcpy(dest[0], src[0], FFT_BUFFER_SIZE * sizeof(SInt16));
    if (nch == 1)
        memcpy(dest[1], src[0], FFT_BUFFER_SIZE * sizeof(SInt16));
    else
        memcpy(dest[1], src[1], FFT_BUFFER_SIZE * sizeof(SInt16));
}

void calc_mono_freq(SInt16 dest[2][FFT_RESULT_SIZE], SInt16 src[2][FFT_BUFFER_SIZE], SInt16 nch, fft_state *state) {
    SInt16 i;
    SInt16 *d, *sl, *sr, tmp[FFT_BUFFER_SIZE];
    if (nch == 1)
        calc_freq(dest[0], src[0], state);
    else {
        d = tmp;
        sl = src[0];
        sr = src[1];
        for (i = 0; i < FFT_BUFFER_SIZE; i++) {
            *(d++) = (*(sl++) + *(sr++)) >> 1;
        }
        calc_freq(dest[0], tmp, state);
    }
}

void calc_stereo_freq(SInt16 dest[2][FFT_RESULT_SIZE], SInt16 src[2][FFT_BUFFER_SIZE], SInt8 nch, fft_state *state) {
    calc_freq(dest[0], src[0], state);
    if (nch == 2)
        calc_freq(dest[1], src[1], state);
    else
        memcpy(dest[1], dest[0], FFT_RESULT_SIZE * sizeof(SInt16));
}

@interface STWaveAnalysis () {
    /// fft 变换
    STAnalysisBufferRef _bufferRef;
    /// 频率/255
    NSArray *_defaultScale;

    NSArray *_defaultScale80;
    /// 放大倍数
    CGFloat _scale;
    fft_state *_fft;
}

@end

@implementation STWaveAnalysis

- (void)dealloc {
    fft_close(_fft);
}

- (id)init {
    self = [super init];
    if (self) {
        _bufferRef = NULL;
        _defaultScale = @[ @(0), @(1), @(2), @(3), @(5), @(7), @(10), @(14), @(20), @(28), @(40), @(54), @(74), @(101), @(137), @(187), @(255) ];
        _defaultScale80 = @[
            @(0),
            @(1),
            @(2),
            @(3),
            @(4),
            @(5),
            @(6),
            @(7),
            @(8),
            @(9),
            @(10),
            @(11),
            @(12),
            @(13),
            @(14),
            @(15),
            @(16),
            @(17),
            @(18),
            @(19),
            @(20),
            @(21),
            @(22),
            @(23),
            @(24),
            @(25),
            @(26),
            @(27),
            @(28),
            @(29),
            @(30),
            @(31),
            @(32),
            @(33),
            @(34),
            @(35),
            @(36),
            @(37),
            @(38),
            @(39),
            @(40),
            @(41),
            @(42),
            @(43),
            @(44),
            @(45),
            @(46),
            @(47),
            @(48),
            @(49),
            @(50),
            @(51),
            @(52),
            @(53),
            @(54),
            @(55),
            @(56),
            @(57),
            @(58),
            @(59),
            @(61),
            @(63),
            @(67),
            @(72),
            @(77),
            @(82),
            @(87),
            @(93),
            @(99),
            @(105),
            @(110),
            @(115),
            @(121),
            @(130),
            @(141),
            @(152),
            @(163),
            @(174),
            @(185),
            @(200),
            @(255)
        ];
        self.constraintsHeight = 100.f;

        _fft = visual_fft_init();
    }
    return self;
}

- (void)setConstraintsHeight:(CGFloat)constraintsHeight {
    if (_constraintsHeight != constraintsHeight) {
        _constraintsHeight = constraintsHeight;
    }
    _scale = constraintsHeight / log(FFT_RESULT_SIZE);
}

// 默认单声道
- (STAnalysisBufferRef)analysisWithData:(NSData *)data {
    return [self analysisWithData:data channels:1];
}
// 如果设置多声道，则分析 stereo
- (STAnalysisBufferRef)analysisWithData:(NSData *)data channels:(NSInteger)chns {
    /// 如果传入数据小于 512 ， 则不分析数据
    chns = (SInt8)chns;
    NSAssert(chns > 0, @"通道数必须大于零");
    if (data.length < FFT_AUDIO_BUFFER_SIZE * chns) {
        return NULL;
    }
    /// 只分析前 512 个值
    SInt16 pcmData[2][FFT_BUFFER_SIZE];

    SInt16 bytes[FFT_AUDIO_BUFFER_SIZE];
    [data getBytes:bytes range:NSMakeRange(0, MIN(data.length, sizeof(bytes)))];

    for (int i = 0; i < FFT_BUFFER_SIZE; i++) {

        if (chns == 1) {
            // 单声道则直接取 数据
            pcmData[0][i] = bytes[i];
            // 将单声道的第二行置空
            pcmData[1][i] = 0;
        } else {
            pcmData[0][i] = bytes[2 * i];
            pcmData[1][i] = bytes[2 * i + 1];
        }
    }

    SInt16 result[2][FFT_RESULT_SIZE];
    if (chns == 1) {
        calc_mono_freq(result, pcmData, chns, _fft);
    } else {
        calc_stereo_freq(result, pcmData, chns, _fft);
    }

    STAnalysisBuffer buffer;
    buffer.channels = chns;
    memcpy(buffer.result, result, 2 * FFT_RESULT_SIZE * sizeof(SInt16));
    _bufferRef = &buffer;
    return _bufferRef;
}

@end

// 获取绘制柱状图所需要的数据
@implementation STWaveAnalysis (SWaveBar)

- (NSArray *)heightForBarWithData:(NSData *)data {

    return [self heightForBarWithData:data channels:1];
}

- (NSArray *)heightForBarWithData:(NSData *)data channels:(NSInteger)channels {
    return [self heightForBarWithData:data channels:channels constraintsFrequency:nil];
}

- (NSArray *)heightForBarWithData:(NSData *)data channels:(NSInteger)channels constraintsFrequency:(NSArray *)frequency {
    if (!data || data.length < FFT_AUDIO_BUFFER_SIZE * channels) {
        return nil;
    }
    if (!frequency) {
        frequency = _defaultScale;
    }
    NSInteger count = frequency.count;
    STAnalysisBufferRef bufferRef = [self analysisWithData:data channels:channels];
    SInt16 freqData[2][FFT_RESULT_SIZE];
    memcpy(freqData, bufferRef->result, 2 * FFT_RESULT_SIZE * sizeof(SInt16));
    NSMutableArray *heights = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count - 1; i++) {
        [heights addObject:@(0.0f)];
    }

    NSInteger max = 0;
    for (int i = 0; i < count - 1; i++) {
        SInt16 a = [[frequency objectAtIndex:i] intValue];
        SInt16 b = [[frequency objectAtIndex:i + 1] intValue];
        max = 0;
        for (int j = a; j < b; j++) {
            if (max < freqData[0][j])
                max = freqData[0][j];
        }
        max >>= 7;
        if (max != 0) {
            max = (SInt16)(log(max) * _scale);
            if (max > self.constraintsHeight - 1)
                max = self.constraintsHeight - 1;
        }
        CGFloat h = [[heights objectAtIndex:i] floatValue];
        if (max > h) {
            h = max;
        } else if (h > 4.0f) {
            h -= 4.0f;
        } else {
            h = 0.0f;
        }
        [heights replaceObjectAtIndex:i withObject:@(h)];
    }
    return heights;
}

@end

@implementation STWaveAnalysis (SLemuria)

- (NSArray *)heightWithData:(NSData *)data channels:(NSInteger)channels constraintsFrequency:(NSArray *)frequency {
    if (!data || data.length < FFT_AUDIO_BUFFER_SIZE * channels) {
        return nil;
    }
    if (!frequency) {
        frequency = _defaultScale80;
    }
    NSInteger count = frequency.count - 1;
    STAnalysisBufferRef bufferRef = [self analysisWithData:data channels:channels];
    SInt16 freqData[2][FFT_RESULT_SIZE];
    memcpy(freqData, bufferRef->result, 2 * FFT_RESULT_SIZE * sizeof(SInt16));
    free(bufferRef);
    CGFloat *heights = malloc(count * sizeof(CGFloat));

    for (int i = 0; i < count; i++) {
        heights[i] = 0;
        SInt16 a = [[frequency objectAtIndex:i] intValue];
        SInt16 b = [[frequency objectAtIndex:i + 1] intValue];
        int max = 0;
        for (int j = a; j < b; j++) {
            max = MAX(freqData[0][j], max);
        }
        if (max != 0) {
            heights[i] = log(max) * 20.0;
            if (heights[i] > self.constraintsHeight - 1)
                heights[i] = self.constraintsHeight - 1;
        }
    }
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        [result addObject:@(heights[i])];
    }
    free(heights);

    return result;
}

@end
