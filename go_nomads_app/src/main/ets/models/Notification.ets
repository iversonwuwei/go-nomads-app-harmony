export interface AppNotification {
  id: string;
  type: string;
  title: string;
  body: string;
  isRead: boolean;
  createdAt: string;
  actionUrl?: string;
}

export function parseNotification(item: Record<string, Object>): AppNotification | null {
  if (!item) return null;
  return {
    id: (item['id'] as string) ?? '',
    type: (item['type'] as string) ?? 'system',
    title: (item['title'] as string) ?? '',
    body: (item['body'] as string) ?? '',
    isRead: (item['isRead'] as boolean) ?? false,
    createdAt: (item['createdAt'] as string) ?? '',
    actionUrl: item['actionUrl'] as string | undefined,
  } as AppNotification;
}
