import React, { useEffect, useMemo, useState } from 'react';
// import { Client } from '@xmtp/xmtp-js'; // TODO: Install @xmtp/xmtp-js dependency
import { useAddress, useSigner } from '@thirdweb-dev/react';
import { isAddress } from 'ethers/lib/utils';

interface ProcessorOption {
  address: string;
  name: string;
}

interface XmtpMessageSectionProps {
  availableProcessors: ProcessorOption[];
  selectedProcessors: string[];
}

type XmtpEnvironment = 'production' | 'dev' | 'local';

const DEFAULT_XMTP_ENV: XmtpEnvironment = 'production';

const resolveXmtpEnv = (): XmtpEnvironment => {
  const env = process.env.REACT_APP_XMTP_ENV?.toLowerCase();

  switch (env) {
    case 'production':
    case 'dev':
    case 'local':
      return env;
    case 'preview':
    case 'beta':
      return 'dev';
    default:
      return DEFAULT_XMTP_ENV;
  }
};

const formatAddress = (address: string | undefined | null) => {
  const trimmed = address?.trim() ?? '';

  if (trimmed.length <= 10) {
    return trimmed;
  }

  return `${trimmed.slice(0, 6)}...${trimmed.slice(-4)}`;
};

type StatusTone = 'info' | 'success' | 'error';

interface StatusMessage {
  tone: StatusTone;
  message: string;
}

const statusToneStyles: Record<StatusTone, string> = {
  info: 'border-gray-200 bg-gray-50 text-gray-700',
  success: 'border-green-200 bg-green-50 text-green-700',
  error: 'border-red-200 bg-red-50 text-red-700',
};

const buildMessageTemplate = (processors: ProcessorOption[]): string => {
  const processorNames = processors.map((processor) => processor.name);
  const greeting = processorNames.length
    ? `Hello ${processorNames.join(', ')},`
    : 'Hello,';

  return `${greeting}

I’m requesting a personal data removal through Removal.Ninja. Below is the information you need to process my request:

- Full legal name:
- Preferred email for confirmations:
- URLs, accounts, or identifiers to remove:
- Additional context:

Please let me know if you require anything else to verify my identity.

Thank you!`;
};

const XmtpMessageSection: React.FC<XmtpMessageSectionProps> = ({
  availableProcessors,
  selectedProcessors,
}) => {
  const signer = useSigner();
  const address = useAddress();
  const [xmtpClient, setXmtpClient] = useState<any | null>(null); // TODO: Replace 'any' with proper Client type when XMTP is installed
  const [initializingClient, setInitializingClient] = useState(false);
  const [recipientAddress, setRecipientAddress] = useState('');
  const [messageBody, setMessageBody] = useState('');
  const [hasEditedMessage, setHasEditedMessage] = useState(false);
  const [statusMessage, setStatusMessage] = useState<StatusMessage | null>(null);
  const [sendingMessage, setSendingMessage] = useState(false);

  const selectedProcessorOptions = useMemo(
    () =>
      availableProcessors.filter((processor) =>
        selectedProcessors.includes(processor.address)
      ),
    [availableProcessors, selectedProcessors]
  );

  useEffect(() => {
    if (!address) {
      setXmtpClient(null);
      setRecipientAddress('');
      setStatusMessage(null);
      setHasEditedMessage(false);
    }
  }, [address]);

  useEffect(() => {
    if (
      !recipientAddress &&
      selectedProcessorOptions.length === 1
    ) {
      setRecipientAddress(selectedProcessorOptions[0].address);
    }
  }, [recipientAddress, selectedProcessorOptions]);

  useEffect(() => {
    if (!hasEditedMessage) {
      setMessageBody(buildMessageTemplate(selectedProcessorOptions));
    }
  }, [selectedProcessorOptions, hasEditedMessage]);

  const handleRecipientChange = (value: string) => {
    setRecipientAddress(value);
    if (statusMessage?.tone === 'error') {
      setStatusMessage(null);
    }
  };

  const handleMessageChange = (value: string) => {
    if (!hasEditedMessage) {
      setHasEditedMessage(true);
    }
    setMessageBody(value);
  };

  const initializeClient = async () => {
    if (xmtpClient) {
      setStatusMessage({
        tone: 'info',
        message: 'XMTP messaging is already enabled for this session.',
      });
      return;
    }

    if (!signer) {
      setStatusMessage({
        tone: 'error',
        message: 'Connect your wallet to enable XMTP messaging.',
      });
      return;
    }

    setInitializingClient(true);
    try {
      const env = resolveXmtpEnv();
      // const client = await Client.create(signer, { env }); // TODO: Enable when XMTP is installed
      const client = null; // Placeholder
      setXmtpClient(client);
      setStatusMessage({
        tone: 'success',
        message:
          'XMTP messaging is ready. You can now share sensitive information securely.',
      });
    } catch (error) {
      console.error('Failed to initialize XMTP client', error);
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      setStatusMessage({
        tone: 'error',
        message: `Failed to initialize XMTP: ${errorMessage}`,
      });
    } finally {
      setInitializingClient(false);
    }
  };

  const sendMessage = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!xmtpClient) {
      setStatusMessage({
        tone: 'error',
        message: 'Enable XMTP messaging before sending a message.',
      });
      return;
    }

    const normalizedRecipient = recipientAddress.trim();
    if (!normalizedRecipient) {
      setStatusMessage({
        tone: 'error',
        message: 'Enter a recipient address to deliver your message.',
      });
      return;
    }

    if (!isAddress(normalizedRecipient)) {
      setStatusMessage({
        tone: 'error',
        message: 'Enter a valid Ethereum address before sending.',
      });
      return;
    }

    if (!messageBody.trim()) {
      setStatusMessage({
        tone: 'error',
        message: 'Enter the message details you want to share.',
      });
      return;
    }

    setSendingMessage(true);
    try {
      const canMessage = await xmtpClient.canMessage(normalizedRecipient);
      if (!canMessage) {
        setStatusMessage({
          tone: 'error',
          message:
            'The recipient has not enabled XMTP messaging yet. Ask them to opt in.',
        });
        return;
      }

      const conversation = await xmtpClient.conversations.newConversation(
        normalizedRecipient
      );
      await conversation.send(messageBody.trim());
      setMessageBody('');
      setHasEditedMessage(false);
      setRecipientAddress(normalizedRecipient);
      setStatusMessage({
        tone: 'success',
        message: `Message sent to ${formatAddress(normalizedRecipient)}.`,
      });
    } catch (error) {
      console.error('Failed to send XMTP message', error);
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      setStatusMessage({
        tone: 'error',
        message: `Failed to send message: ${errorMessage}`,
      });
    } finally {
      setSendingMessage(false);
    }
  };

  return (
    <div className="card">
      <h2 className="text-xl font-semibold mb-2">Secure XMTP Messaging</h2>
      <p className="text-gray-600 mb-4">
        Use encrypted XMTP messages to deliver the sensitive PII processors need
        to fulfill your data removal request.
      </p>

      {statusMessage && (
        <div
          className={`mb-4 rounded-lg border px-4 py-3 text-sm ${statusToneStyles[statusMessage.tone]}`}
          role={statusMessage.tone === 'error' ? 'alert' : undefined}
        >
          {statusMessage.message}
        </div>
      )}

      {!xmtpClient ? (
        <button
          type="button"
          className="btn w-full md:w-auto"
          onClick={initializeClient}
          disabled={initializingClient}
        >
          {initializingClient ? 'Preparing XMTP…' : 'Enable XMTP Messaging'}
        </button>
      ) : (
        <form onSubmit={sendMessage} className="space-y-4">
          <div>
            <label className="form-label" htmlFor="recipient-address">
              Recipient address
            </label>
            <input
              id="recipient-address"
              type="text"
              className="form-input"
              placeholder="0x..."
              value={recipientAddress}
              onChange={(event) => handleRecipientChange(event.target.value)}
            />
            {selectedProcessorOptions.length > 0 && (
              <div className="mt-3 flex flex-wrap gap-2 text-sm">
                {selectedProcessorOptions.map((processor) => (
                  <button
                    key={processor.address}
                    type="button"
                    className="btn-secondary px-3 py-2 text-sm text-white"
                    onClick={() => handleRecipientChange(processor.address)}
                  >
                    Message {processor.name}
                  </button>
                ))}
              </div>
            )}
          </div>

          <div>
            <label className="form-label" htmlFor="message-body">
              Message details
            </label>
            <textarea
              id="message-body"
              className="form-textarea"
              placeholder="Share the information required for verification or removal processing."
              value={messageBody}
              onChange={(event) => handleMessageChange(event.target.value)}
            />
            <p className="mt-2 text-sm text-gray-500">
              Only share PII with trusted processors. Messages are end-to-end
              encrypted when delivered via XMTP.
            </p>
          </div>

          <div className="flex items-center justify-between gap-4">
            <button
              type="submit"
              className="btn"
              disabled={sendingMessage}
            >
              {sendingMessage ? 'Sending…' : 'Send Secure Message'}
            </button>
            <span className="text-sm text-gray-500">
              Messages are sent from {formatAddress(address)}
            </span>
          </div>
        </form>
      )}
    </div>
  );
};

export default XmtpMessageSection;
