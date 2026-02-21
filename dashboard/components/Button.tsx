import type { CSSProperties } from 'react'
import { gradients, colors, borderRadius, shadows, transitions } from './design-tokens'

export type ButtonVariant = 'primary' | 'secondary' | 'tertiary' | 'ghost' | 'danger'
export type ButtonSize = 'sm' | 'md' | 'lg'

interface ButtonProps {
  children: React.ReactNode
  variant?: ButtonVariant
  size?: ButtonSize
  disabled?: boolean
  onClick?: () => void
  href?: string
  style?: CSSProperties
}

const getButtonStyles = (variant: ButtonVariant, size: ButtonSize, disabled: boolean): CSSProperties => {
  const baseStyles: CSSProperties = {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontWeight: 700,
    border: 'none',
    cursor: disabled ? 'not-allowed' : 'pointer',
    transition: transitions.normal,
    textDecoration: 'none',
    opacity: disabled ? 0.5 : 1,
    transform: 'translateY(0)',
  }

  const sizeStyles: Record<ButtonSize, CSSProperties> = {
    sm: {
      padding: '0.5rem 1rem',
      fontSize: '0.875rem',
      borderRadius: borderRadius.md,
    },
    md: {
      padding: '1rem 2rem',
      fontSize: '1rem',
      borderRadius: borderRadius.lg,
    },
    lg: {
      padding: '1.25rem 2.5rem',
      fontSize: '1.125rem',
      borderRadius: borderRadius.lg,
    }
  }

  const variantStyles: Record<ButtonVariant, CSSProperties> = {
    primary: {
      background: gradients.brand,
      color: 'white',
      boxShadow: '0 4px 15px rgba(255, 29, 108, 0.4)',
    },
    secondary: {
      background: gradients.pinkToViolet,
      color: 'white',
      boxShadow: '0 4px 15px rgba(156, 39, 176, 0.4)',
    },
    tertiary: {
      background: gradients.blueToViolet,
      color: 'white',
      boxShadow: '0 4px 15px rgba(41, 121, 255, 0.4)',
    },
    ghost: {
      background: 'transparent',
      color: colors.brand.hotPink,
      border: `2px solid ${colors.brand.hotPink}`,
    },
    danger: {
      background: colors.semantic.error,
      color: 'white',
      boxShadow: '0 4px 15px rgba(239, 68, 68, 0.4)',
    }
  }

  return { ...baseStyles, ...sizeStyles[size], ...variantStyles[variant] }
}

export function Button({
  children,
  variant = 'primary',
  size = 'md',
  disabled = false,
  onClick,
  href,
  style
}: ButtonProps) {
  const buttonStyles = getButtonStyles(variant, size, disabled)

  if (href) {
    return (
      <a
        href={href}
        style={{ ...buttonStyles, ...style }}
        onMouseEnter={(e) => {
          if (!disabled) {
            e.currentTarget.style.transform = 'translateY(-2px)'
            e.currentTarget.style.boxShadow = shadows.xl
          }
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.transform = 'translateY(0)'
        }}
      >
        {children}
      </a>
    )
  }

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      style={{ ...buttonStyles, ...style }}
      onMouseEnter={(e) => {
        if (!disabled) {
          e.currentTarget.style.transform = 'translateY(-2px)'
          e.currentTarget.style.boxShadow = shadows.xl
        }
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'translateY(0)'
      }}
    >
      {children}
    </button>
  )
}
