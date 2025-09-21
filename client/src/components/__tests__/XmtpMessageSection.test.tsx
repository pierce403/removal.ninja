import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';

import XmtpMessageSection from '../XmtpMessageSection';

const mockCreate = jest.fn();
const mockCanMessage = jest.fn();
const mockSend = jest.fn();
const mockNewConversation = jest.fn();

jest.mock('@xmtp/xmtp-js', () => ({
  Client: {
    create: (...args: unknown[]) => mockCreate(...args),
  },
}));

const mockUseSigner = jest.fn();
const mockUseAddress = jest.fn();

jest.mock('@thirdweb-dev/react', () => ({
  useSigner: () => mockUseSigner(),
  useAddress: () => mockUseAddress(),
}));

describe('XmtpMessageSection', () => {
  beforeEach(() => {
    mockCreate.mockReset();
    mockCanMessage.mockReset();
    mockSend.mockReset();
    mockNewConversation.mockReset();
    mockUseSigner.mockReset();
    mockUseAddress.mockReset();

    mockUseSigner.mockReturnValue({});
    mockUseAddress.mockReturnValue('0x1234567890abcdef1234567890abcdef12345678');

    mockCanMessage.mockResolvedValue(true);
    mockSend.mockResolvedValue(undefined);
    mockNewConversation.mockResolvedValue({
      send: mockSend,
    });

    mockCreate.mockResolvedValue({
      canMessage: mockCanMessage,
      conversations: {
        newConversation: mockNewConversation,
      },
    });
  });

  const baseProps: React.ComponentProps<typeof XmtpMessageSection> = {
    availableProcessors: [
      {
        address: '0xabc1230000000000000000000000000000000001',
        name: 'PrivacyPro Services',
      },
      {
        address: '0xabc1230000000000000000000000000000000002',
        name: 'FastRemoval Inc',
      },
    ],
    selectedProcessors: [
      '0xabc1230000000000000000000000000000000001',
      '0xabc1230000000000000000000000000000000002',
    ],
  };

  it('prefills the secure message template once XMTP is enabled', async () => {
    render(<XmtpMessageSection {...baseProps} />);

    fireEvent.click(screen.getByRole('button', { name: /enable xmtp messaging/i }));

    await waitFor(() => {
      expect(mockCreate).toHaveBeenCalled();
    });

    const textarea = await screen.findByLabelText(/message details/i);
    const message = (textarea as HTMLTextAreaElement).value;
    expect(message).toContain('Hello PrivacyPro Services, FastRemoval Inc,');
    expect(message).toContain('- Full legal name:');
  });

  it('lets the user populate the recipient address from a processor shortcut', async () => {
    render(<XmtpMessageSection {...baseProps} />);

    fireEvent.click(screen.getByRole('button', { name: /enable xmtp messaging/i }));

    await screen.findByLabelText(/recipient address/i);

    fireEvent.click(screen.getByRole('button', { name: /message privacypro services/i }));

    const recipientInput = await screen.findByLabelText(/recipient address/i);
    expect(recipientInput).toHaveValue('0xabc1230000000000000000000000000000000001');
  });
});
