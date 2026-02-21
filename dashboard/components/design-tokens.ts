// BlackRoad Official Design System Tokens
// Reference: ~/BLACKROAD_BRAND_SYSTEM.md

export const colors = {
  brand: {
    hotPink: '#FF1D6C',
    amber: '#F5A623',
    electricBlue: '#2979FF',
    violet: '#9C27B0',
  },
  primary: {
    pink: '#FF1D6C',
    amber: '#F5A623',
    blue: '#2979FF',
    violet: '#9C27B0',
  },
  neutral: {
    black: '#000000',
    darkGray: '#111111',
    gray: '#1a1a1a',
    midGray: '#666666',
    lightGray: '#999999',
    silver: '#b0b0b0',
    offWhite: '#e0e0e0',
    white: '#FFFFFF',
  },
  semantic: {
    success: '#4ade80',
    warning: '#F5A623',
    error: '#ef4444',
    info: '#2979FF',
  },
}

export const gradients = {
  brand: 'linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)',
  pinkToViolet: 'linear-gradient(135deg, #FF1D6C 0%, #9C27B0 100%)',
  amberToPink: 'linear-gradient(135deg, #F5A623 0%, #FF1D6C 100%)',
  blueToViolet: 'linear-gradient(135deg, #2979FF 0%, #9C27B0 100%)',
}

// Golden Ratio spacing: 8 -> 13 -> 21 -> 34 -> 55 -> 89 -> 144
export const spacing = {
  xs: '8px',
  sm: '13px',
  md: '21px',
  lg: '34px',
  xl: '55px',
  '2xl': '89px',
  '3xl': '144px',
}

export const borderRadius = {
  sm: '4px',
  md: '8px',
  lg: '13px',
  xl: '21px',
  '2xl': '34px',
  full: '9999px',
}

export const shadows = {
  sm: '0 1px 2px 0 rgba(0, 0, 0, 0.3)',
  md: '0 4px 6px -1px rgba(0, 0, 0, 0.4)',
  lg: '0 10px 15px -3px rgba(0, 0, 0, 0.4)',
  xl: '0 20px 25px -5px rgba(0, 0, 0, 0.4)',
  glow: '0 0 40px rgba(255, 29, 108, 0.2)',
  glowAmber: '0 0 40px rgba(245, 166, 35, 0.2)',
}

export const transitions = {
  fast: 'all 0.15s ease',
  normal: 'all 0.2s ease',
  slow: 'all 0.3s ease',
}

export const typography = {
  fontFamily: {
    sans: "'SF Pro Display', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    mono: "'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, monospace",
  },
  fontSize: {
    xs: '0.75rem',
    sm: '0.85rem',
    base: '1rem',
    lg: '1.1rem',
    xl: '1.25rem',
    '2xl': '1.5rem',
    '3xl': '2rem',
    '4xl': '2.5rem',
    '5xl': '3.25rem',
  },
}

export const breakpoints = {
  sm: '640px',
  md: '768px',
  lg: '1024px',
  xl: '1280px',
}
