# Risk Meter UI - Speedometer Style Gauge

## Overview

Beautiful speedometer-style risk meter that displays the risk score from 0-100 with smooth animations and color-coded zones.

## Features

### Visual Design
- **Speedometer Gauge**: Half-circle arc design like a car speedometer
- **Color Gradient**: Smooth transition from green → yellow → orange → red
- **Animated Needle**: Points to current risk score with smooth animation
- **Glowing Effects**: Active zone glows with shadow effects
- **Tick Marks**: Numbers 0, 20, 40, 60, 80, 100 marked on the arc

### Risk Zones
1. **LOW (0-19)**: Green - Safe zone
2. **MODERATE (20-39)**: Orange - Caution zone
3. **HIGH (40-69)**: Deep Orange - Warning zone
4. **SEVERE (70-100)**: Red - Danger zone

### Animations
- **Smooth Transitions**: 1.5-second ease-out animation when score changes
- **Needle Movement**: Animated needle follows score changes
- **Glow Effects**: Active zone indicator glows
- **Color Transitions**: Smooth color changes based on score

### Components

#### Outer Ring
- Black background circle
- Gradient color arc (green to red)
- 25px stroke width
- Semi-transparent inactive zones

#### Active Arc
- Filled from 0 to current score
- Bright color based on risk level
- Gradient shader for depth
- Rounded stroke caps

#### Needle
- Points to current score
- 4px width
- Color matches risk level
- Smooth rotation animation

#### Center Display
- Large risk score number (56px)
- "RISK SCORE" label
- Color-coded text
- Glow shadow effect

#### Zone Indicators
- Four dots below gauge
- Active zone glows
- Labels: LOW, MODERATE, HIGH, SEVERE
- Color-coded

## Implementation

### Widget Structure
```dart
RiskMeter(
  riskScore: 85,
  status: 'SEVERE',
)
```

### Custom Painter
- `RiskMeterPainter`: Draws the entire gauge
- Canvas-based rendering
- Efficient repainting on score changes

### Animation
- `AnimationController`: 1500ms duration
- `CurvedAnimation`: Ease-out cubic curve
- Tween from old score to new score
- Smooth needle movement

## Usage

### In Home Screen
```dart
Widget _buildStatusCard() {
  return RiskMeter(
    riskScore: _riskScore,
    status: _getRiskText(),
  );
}
```

### Score Updates
- Automatically animates when `_riskScore` changes
- No manual animation triggering needed
- Smooth transitions between values

## Visual Specifications

### Colors
- **Green**: `Colors.green` (0-19)
- **Light Green**: `Colors.lightGreen` (20-39)
- **Orange**: `Colors.orange` (40-59)
- **Deep Orange**: `Colors.deepOrange` (60-79)
- **Red**: `Colors.red` (80-100)

### Dimensions
- **Gauge Height**: 250px
- **Gauge Radius**: 40% of width
- **Stroke Width**: 25px
- **Needle Length**: Radius - 10px
- **Center Circle**: 12px radius
- **Center Dot**: 8px radius

### Typography
- **Title**: 24px, bold, letter-spacing: 2
- **Score**: 56px, bold, with glow shadow
- **Label**: 14px, semi-bold
- **Zone Labels**: 12px

## Comparison with Original Design

### Similarities
 Speedometer half-circle design
 Color gradient from green to red
 Large centered score display
 Zone labels (LOW, MODERATE, HIGH, SEVERE)
 Needle pointing to score
 Tick marks with numbers

### Enhancements
 Smooth animations
 Glowing active zone
 Gradient shader on active arc
 Pulsing zone indicators
 Responsive design
 Dark theme compatible

## Performance

### Optimization
- Efficient canvas rendering
- Only repaints when score changes
- Smooth 60fps animations
- Minimal memory footprint

### Battery Impact
- Lightweight widget
- No continuous animations (only on change)
- GPU-accelerated rendering

## Customization

### Adjustable Parameters
```dart
// In RiskMeterPainter
final radius = size.width * 0.4;  // Gauge size
final strokeWidth = 25;            // Arc thickness
final tickCount = 10;              // Number of ticks
```

### Color Scheme
```dart
Color _getColorForScore(double score) {
  if (score < 20) return Colors.green;
  if (score < 40) return Colors.lightGreen;
  if (score < 60) return Colors.orange;
  if (score < 80) return Colors.deepOrange;
  return Colors.red;
}
```

### Animation Duration
```dart
_controller = AnimationController(
  duration: const Duration(milliseconds: 1500),  // Adjust speed
  vsync: this,
);
```

## Testing

### Test Different Scores
```dart
// Low risk
RiskMeter(riskScore: 10, status: 'LOW')

// Moderate risk
RiskMeter(riskScore: 30, status: 'MODERATE')

// High risk
RiskMeter(riskScore: 55, status: 'HIGH')

// Severe risk
RiskMeter(riskScore: 85, status: 'SEVERE')
```

### Test Animations
1. Start with score 0
2. Increase to 50 - watch needle animate
3. Increase to 85 - watch color change
4. Decrease to 20 - watch smooth transition

## Future Enhancements

### Possible Additions
1. **Pulsing Animation**: Pulse when in danger zone
2. **Sound Effects**: Beep when entering danger zone
3. **Haptic Feedback**: Vibrate on zone changes
4. **History Graph**: Show score over time
5. **Threshold Markers**: Custom warning thresholds
6. **Multiple Needles**: Show current + average score

## Summary

The Risk Meter provides a beautiful, intuitive visualization of the risk score with smooth animations and clear color-coded zones. It's inspired by automotive speedometers and provides instant visual feedback about the current safety status.

Key benefits:
-  Intuitive speedometer design
-  Smooth animations
-  Clear color coding
-  Professional appearance
-  Easy to understand at a glance
-  Responsive and performant
