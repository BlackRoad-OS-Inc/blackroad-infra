import type { CSSProperties, ReactNode } from 'react'
import { borderRadius, shadows, transitions } from './design-tokens'

interface CardProps {
  children: ReactNode
  variant?: 'default' | 'elevated' | 'outlined' | 'glass'
  gradient?: string
  style?: CSSProperties
  onClick?: () => void
  hoverable?: boolean
}

export function Card({
  children,
  variant = 'default',
  gradient,
  style,
  onClick,
  hoverable = false
}: CardProps) {
  const baseStyles: CSSProperties = {
    padding: '21px',
    borderRadius: borderRadius.lg,
    transition: transitions.normal,
    cursor: onClick ? 'pointer' : 'default'
  }

  const variantStyles: Record<string, CSSProperties> = {
    default: {
      backgroundColor: '#111',
      border: '1px solid #222',
      boxShadow: shadows.md,
    },
    elevated: {
      backgroundColor: '#111',
      border: '1px solid #222',
      boxShadow: shadows.xl,
    },
    outlined: {
      backgroundColor: 'transparent',
      border: '1px solid #333',
    },
    glass: {
      background: 'rgba(255, 255, 255, 0.05)',
      backdropFilter: 'blur(10px)',
      border: '1px solid rgba(255, 255, 255, 0.1)',
    }
  }

  const cardStyles = {
    ...baseStyles,
    ...variantStyles[variant],
    ...(gradient && { background: gradient }),
    ...style
  }

  return (
    <div
      style={cardStyles}
      onClick={onClick}
      onMouseEnter={(e) => {
        if (hoverable || onClick) {
          e.currentTarget.style.transform = 'translateY(-4px)'
          e.currentTarget.style.boxShadow = shadows.xl
        }
      }}
      onMouseLeave={(e) => {
        if (hoverable || onClick) {
          e.currentTarget.style.transform = 'translateY(0)'
          e.currentTarget.style.boxShadow = variant === 'elevated' ? shadows.xl : shadows.md
        }
      }}
    >
      {children}
    </div>
  )
}
