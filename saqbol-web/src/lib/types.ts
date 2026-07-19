export interface CategoryCount {
  name: string;
  count: number;
}

export interface Overview {
  total_users: number;
  total_messages: number;
  scam_messages: number;
  suspicious_messages: number;
  alerted_call_sessions: number;
  category_distribution: CategoryCount[];
}

export interface AdminMessage {
  id: string;
  phone: string;
  channel: string;
  text: string;
  source_number: string;
  probability: number;
  verdict: string;
  category: string;
  triggers: string;
  created_at: string;
}

export interface ModelVersion {
  id: string;
  name: string;
  metrics: string;
  trained_at: string;
}
