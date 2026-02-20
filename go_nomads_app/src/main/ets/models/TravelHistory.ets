export interface TravelHistory {
  id: string;
  backendId?: string;
  city: string;
  cityName?: string;
  country: string;
  countryCode?: string;
  cityId?: string;
  arrivalTime: string;
  departureTime?: string;
  isOngoing: boolean;
  durationDays?: number;
  status?: string;
}

export function parseTravelHistory(item: Record<string, Object>): TravelHistory | null {
  if (!item) return null;
  const parseString = (value: Object | undefined): string | undefined => {
    if (typeof value === 'string') return value;
    if (typeof value === 'number' || typeof value === 'boolean') return String(value);
    return undefined;
  };

  const parseBoolean = (value: Object | undefined): boolean => {
    if (typeof value === 'boolean') return value;
    if (typeof value === 'number') return value !== 0;
    if (typeof value === 'string') {
      const normalized = value.trim().toLowerCase();
      return normalized === 'true' || normalized === '1' || normalized === 'yes';
    }
    return false;
  };

  const rawDuration = item['durationDays'];
  let durationDays: number | undefined = undefined;
  if (typeof rawDuration === 'number') {
    durationDays = rawDuration;
  } else if (typeof rawDuration === 'string') {
    const parsed = parseInt(rawDuration, 10);
    durationDays = isNaN(parsed) ? undefined : parsed;
  }

  const id =
    parseString(item['id']) ??
    parseString(item['backendId']) ??
    parseString(item['travelHistoryId']) ??
    '';

  const backendId =
    parseString(item['backendId']) ??
    parseString(item['travelHistoryId']) ??
    parseString(item['id']);

  const city = parseString(item['city']) ?? parseString(item['cityName']) ?? '';
  const country = parseString(item['country']) ?? parseString(item['countryName']) ?? '';
  const cityId = parseString(item['cityId']) ?? parseString(item['destinationCityId']);
  const arrivalTime =
    parseString(item['arrivalTime']) ??
    parseString(item['checkInTime']) ??
    parseString(item['startTime']) ??
    '';
  const departureTime =
    parseString(item['departureTime']) ??
    parseString(item['checkOutTime']) ??
    parseString(item['endTime']);

  return {
    id: id,
    backendId: backendId,
    city: city,
    cityName: parseString(item['cityName']),
    country: country,
    countryCode: parseString(item['countryCode']),
    cityId: cityId,
    arrivalTime: arrivalTime,
    departureTime: departureTime,
    isOngoing: parseBoolean(item['isOngoing']),
    durationDays: durationDays,
    status: parseString(item['status']),
  } as TravelHistory;
}
