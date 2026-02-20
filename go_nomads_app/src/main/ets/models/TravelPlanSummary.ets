export interface TravelPlanSummary {
  id: string;
  cityId?: string;
  cityName?: string;
  cityImage?: string;
  durationDays?: number;
  destinationsCount?: number;
  budgetLevel?: string;
  travelStyle?: string;
  departureDate?: string;
  createdAt?: string;
  status?: string;
}

function parseNum(raw: Object | undefined): number | undefined {
  if (typeof raw === 'number') return raw;
  if (typeof raw === 'string') {
    const parsed = Number(raw);
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

function parseStr(raw: Object | undefined): string | undefined {
  if (typeof raw === 'string') return raw;
  return undefined;
}

export function parseTravelPlanSummary(item: Record<string, Object>): TravelPlanSummary | null {
  if (!item) return null;
  return {
    id: parseStr(item['id']) ?? '',
    cityId: parseStr(item['cityId']),
    cityName: parseStr(item['cityName']),
    cityImage: parseStr(item['cityImage']),
    durationDays: parseNum(item['duration']) ?? parseNum(item['durationDays']),
    destinationsCount: parseNum(item['destinationsCount']),
    budgetLevel: parseStr(item['budgetLevel']) ?? parseStr(item['budget']),
    travelStyle: parseStr(item['travelStyle']),
    departureDate: parseStr(item['departureDate']),
    createdAt: parseStr(item['createdAt']),
    status: parseStr(item['status']),
  } as TravelPlanSummary;
}
