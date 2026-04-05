interface SpinnerProps {
  className?: string;
}

export default function Spinner({ className = '' }: SpinnerProps) {
  return (
    <span
      className={`spinner inline-block align-middle ${className}`.trim()}
      aria-hidden='true'
    />
  );
}
