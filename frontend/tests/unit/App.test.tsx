import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from '@/App';

describe('App', () => {
  it('renders without crashing', () => {
    render(<App />);
    // The Vite default template has a heading or text we can verify
    expect(document.body).toBeInTheDocument();
  });

  it('displays the Vite + React heading', () => {
    render(<App />);
    expect(screen.getByText(/Vite \+ React/i)).toBeInTheDocument();
  });
});
