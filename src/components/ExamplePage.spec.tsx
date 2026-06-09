import { render, screen } from '@testing-library/react';
import ExamplePage from './ExamplePage';

describe('ExamplePage', () => {
  it('renders the page heading', () => {
    render(<ExamplePage />);
    expect(screen.getByRole('heading', { name: 'Hello, plugin!' })).toBeInTheDocument();
  });

  it('renders the success message', () => {
    render(<ExamplePage />);
    expect(screen.getByText('Your plugin is working.')).toBeInTheDocument();
  });
});
