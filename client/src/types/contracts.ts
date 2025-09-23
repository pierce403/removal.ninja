// TypeScript interfaces for RemovalNinja modular contract system

// ============ Data Broker Registry Types ============

export interface DataBroker {
  id: number;
  name: string;
  website: string;
  removalLink: string;
  contact: string;
  weight: number;
  isActive: boolean;
  totalRemovals: number;
  totalDisputes: number;
}

export interface BrokerSubmission {
  name: string;
  website: string;
  removalLink: string;
  contact: string;
  weight: number;
}

// ============ Task Factory Types ============

export interface TaskParams {
  brokerId: number;
  subjectCommit: string; // bytes32 as hex string
  payout: string; // BigNumber as string
  duration: number; // seconds
  description?: string; // Optional for now in ultra-simple version
}

export interface Worker {
  isRegistered: boolean;
  stake: string; // BigNumber as string
  completedTasks: number;
  successRate: number; // 0-100
  reputation: number; // 0-100
  description: string;
  isSlashed: boolean;
}

// ============ Removal Task Types ============

export enum TaskStatus {
  Created = 0,
  Requested = 1,
  Responded = 2,
  Verified = 3,
  Disputed = 4,
  Failed = 5,
  Refunded = 6
}

export interface RemovalTask {
  taskId: number;
  brokerId: number;
  subjectCommit: string; // bytes32 as hex string
  creator: string; // address
  payout: string; // BigNumber as string
  weight: number;
  deadline: number; // timestamp
  currentStatus: TaskStatus;
  assignedWorker?: string; // address
  createdAt: number; // timestamp
  requestedAt?: number; // timestamp
  respondedAt?: number; // timestamp
  completedAt?: number; // timestamp
  evidenceCount: number;
  isDisputed: boolean;
}

export interface Evidence {
  evidenceCid: string; // IPFS/Arweave CID
  summary: string;
  timestamp: number;
  submitter: string; // address
}

export interface TaskSummary {
  id: number;
  broker: number;
  status: TaskStatus;
  worker: string; // address
  payoutAmount: string; // BigNumber as string
  taskDeadline: number; // timestamp
  evidenceCount: number;
  disputed: boolean;
}

// ============ Contract Statistics ============

export interface RegistryStats {
  totalBrokers: number;
  activeBrokers: number;
}

export interface FactoryStats {
  totalTasks: number;
}

export interface TokenStats {
  totalSupply: string; // BigNumber as string
  userBalance: string; // BigNumber as string
  allowance: string; // BigNumber as string
}

// ============ User Interface Types ============

export interface UserTaskData {
  task: RemovalTask;
  broker: DataBroker;
  evidence: Evidence[];
}

export interface WorkerDashboardData {
  worker: Worker;
  assignedTasks: RemovalTask[];
  availableTasks: RemovalTask[];
}

export interface UserDashboardData {
  userTasks: UserTaskData[];
  tokenBalance: string;
  isStakingForRemoval: boolean;
  stakeAmount: string;
}

// ============ Form Types ============

export interface CreateTaskForm {
  brokerId: string;
  payout: string;
  duration: string; // in days, will be converted to seconds
  description: string;
}

export interface AddBrokerForm {
  name: string;
  website: string;
  removalLink: string;
  contact: string;
  weight: string;
}

export interface RegisterWorkerForm {
  stakeAmount: string;
  description: string;
}

export interface SubmitEvidenceForm {
  evidenceCid: string;
  summary: string;
}

// ============ Network & Contract Types ============

export interface NetworkConfig {
  chainId: number;
  name: string;
  rpcUrl: string;
  blockExplorer: string;
  nativeCurrency: {
    name: string;
    symbol: string;
    decimals: number;
  };
}

export interface ContractConfig {
  address: string;
  abi: any[]; // Contract ABI
}

export interface ContractAddresses {
  REMOVAL_NINJA_TOKEN: string;
  DATA_BROKER_REGISTRY: string;
  TASK_FACTORY: string;
}

// ============ Event Types ============

export interface BrokerAddedEvent {
  brokerId: number;
  name: string;
  weight: number;
}

export interface TaskCreatedEvent {
  taskId: number;
  creator: string;
  brokerId: number;
  taskContract: string;
  payout: string;
}

export interface WorkerRegisteredEvent {
  worker: string;
  stake: string;
  description: string;
}

export interface TaskCompletedEvent {
  taskId: number;
  worker: string;
  payout: string;
}

// ============ Error Types ============

export interface ContractError {
  code: string;
  message: string;
  transaction?: string;
}

export interface ValidationError {
  field: string;
  message: string;
}

// ============ Utility Types ============

export type Address = string;
export type BigNumberString = string;
export type Timestamp = number;
export type TokenAmount = string;

// ============ Contract Interaction Types ============

export interface TransactionResult {
  hash: string;
  success: boolean;
  error?: string;
}

export interface ContractCall<T = any> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

// ============ Hook Return Types ============

export interface UseContractReturn<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

export interface UseTransactionReturn {
  execute: (args: any[]) => Promise<TransactionResult>;
  loading: boolean;
  error: string | null;
}

// ============ Component Props Types ============

export interface BrokerCardProps {
  broker: DataBroker;
  onSelect?: (brokerId: number) => void;
  isSelected?: boolean;
  showDetails?: boolean;
}

export interface TaskCardProps {
  task: RemovalTask;
  broker: DataBroker;
  onViewDetails?: (taskId: number) => void;
  onTakeAction?: (taskId: number, action: string) => void;
  userRole?: 'creator' | 'worker' | 'viewer';
}

export interface StatsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: React.ReactNode;
  trend?: 'up' | 'down' | 'neutral';
}

// ============ Constants ============

export const TASK_STATUS_LABELS: Record<TaskStatus, string> = {
  [TaskStatus.Created]: 'Created',
  [TaskStatus.Requested]: 'Removal Requested',
  [TaskStatus.Responded]: 'Broker Responded',
  [TaskStatus.Verified]: 'Verified Complete',
  [TaskStatus.Disputed]: 'Under Dispute',
  [TaskStatus.Failed]: 'Failed',
  [TaskStatus.Refunded]: 'Refunded',
};

export const TASK_STATUS_COLORS: Record<TaskStatus, string> = {
  [TaskStatus.Created]: 'bg-gray-100 text-gray-800',
  [TaskStatus.Requested]: 'bg-blue-100 text-blue-800',
  [TaskStatus.Responded]: 'bg-yellow-100 text-yellow-800',
  [TaskStatus.Verified]: 'bg-green-100 text-green-800',
  [TaskStatus.Disputed]: 'bg-red-100 text-red-800',
  [TaskStatus.Failed]: 'bg-red-100 text-red-800',
  [TaskStatus.Refunded]: 'bg-gray-100 text-gray-800',
};

export const WEIGHT_LABELS: Record<number, string> = {
  100: 'Standard',
  200: 'Medium Impact',
  300: 'High Impact',
};

export const WEIGHT_COLORS: Record<number, string> = {
  100: 'bg-gray-100 text-gray-800',
  200: 'bg-yellow-100 text-yellow-800', 
  300: 'bg-red-100 text-red-800',
};
