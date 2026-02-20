export interface VisitedPlace {
  id: string;
  travelHistoryId: string;
  placeName?: string;
  placeType?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  arrivalTime: string;
  departureTime?: string;
  durationMinutes?: number;
  formattedDuration?: string;
  isHighlight: boolean;
  iconType?: string;
}

export interface PaginatedVisitedPlaces {
  items: VisitedPlace[];
  totalCount: number;
  page: number;
  pageSize: number;
}

export interface CityWeather {
  temperature: number;
  condition?: string;
  icon?: string;
}

export interface VisitedPlacesCitySummary {
  cityId: string;
  cityName: string;
  cityNameEn?: string;
  country: string;
  imageUrl?: string;
  travelDate?: string;
  lastVisitDate?: string;
  totalDurationDays: number;
  weather?: CityWeather;
  overallScore?: number;
  averageMonthlyCost?: number;
  coworkingSpaceCount: number;
  visitedPlaces: PaginatedVisitedPlaces;
}

export function parseVisitedPlace(item: Record<string, Object>): VisitedPlace | null {
  if (!item) return null;

  const parseString = (value: Object | undefined): string | undefined => {
    if (typeof value === 'string') return value;
    if (typeof value === 'number' || typeof value === 'boolean') return String(value);
    return undefined;
  };

  const parseNumber = (value: Object | undefined): number | undefined => {
    if (typeof value === 'number') return value;
    if (typeof value === 'string') {
      const n = Number(value);
      return isNaN(n) ? undefined : n;
    }
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

  const id = parseString(item['id']) ?? '';
  const travelHistoryId = parseString(item['travelHistoryId']) ?? '';
  const arrivalTime = parseString(item['arrivalTime']) ?? '';

  return {
    id,
    travelHistoryId,
    placeName: parseString(item['placeName']),
    placeType: parseString(item['placeType']),
    address: parseString(item['address']),
    latitude: parseNumber(item['latitude']),
    longitude: parseNumber(item['longitude']),
    arrivalTime,
    departureTime: parseString(item['departureTime']),
    durationMinutes: parseNumber(item['durationMinutes']),
    formattedDuration: parseString(item['formattedDuration']),
    isHighlight: parseBoolean(item['isHighlight']),
    iconType: parseString(item['iconType']),
  };
}

export function parsePaginatedVisitedPlaces(item: Record<string, Object> | undefined): PaginatedVisitedPlaces {
  if (!item) {
    return {
      items: [],
      totalCount: 0,
      page: 1,
      pageSize: 20,
    };
  }

  const parseNumber = (value: Object | undefined, fallback: number): number => {
    if (typeof value === 'number') return value;
    if (typeof value === 'string') {
      const n = Number(value);
      return isNaN(n) ? fallback : n;
    }
    return fallback;
  };

  const rawItems = item['items'];
  const items: VisitedPlace[] = [];
  if (rawItems instanceof Array) {
    for (let i = 0; i < rawItems.length; i++) {
      const parsed = parseVisitedPlace(rawItems[i] as Record<string, Object>);
      if (parsed) {
        items.push(parsed);
      }
    }
  }

  return {
    items,
    totalCount: parseNumber(item['totalCount'], items.length),
    page: parseNumber(item['page'], 1),
    pageSize: parseNumber(item['pageSize'], 20),
  };
}

export function parseVisitedPlacesCitySummary(item: Record<string, Object>): VisitedPlacesCitySummary | null {
  if (!item) return null;

  const parseString = (value: Object | undefined): string | undefined => {
    if (typeof value === 'string') return value;
    if (typeof value === 'number' || typeof value === 'boolean') return String(value);
    return undefined;
  };

  const parseNumber = (value: Object | undefined): number | undefined => {
    if (typeof value === 'number') return value;
    if (typeof value === 'string') {
      const n = Number(value);
      return isNaN(n) ? undefined : n;
    }
    return undefined;
  };

  const weatherObj = item['weather'] as Record<string, Object> | undefined;
  const visitedPlacesObj = item['visitedPlaces'] as Record<string, Object> | undefined;

  const cityId = parseString(item['cityId']) ?? '';
  const cityName = parseString(item['cityName']) ?? '';
  const country = parseString(item['country']) ?? '';

  return {
    cityId,
    cityName,
    cityNameEn: parseString(item['cityNameEn']),
    country,
    imageUrl: parseString(item['imageUrl']),
    travelDate: parseString(item['travelDate']),
    lastVisitDate: parseString(item['lastVisitDate']),
    totalDurationDays: parseNumber(item['totalDurationDays']) ?? 0,
    weather: weatherObj ? {
      temperature: parseNumber(weatherObj['temperature']) ?? 0,
      condition: parseString(weatherObj['condition']),
      icon: parseString(weatherObj['icon']),
    } : undefined,
    overallScore: parseNumber(item['overallScore']),
    averageMonthlyCost: parseNumber(item['averageMonthlyCost']),
    coworkingSpaceCount: parseNumber(item['coworkingSpaceCount']) ?? 0,
    visitedPlaces: parsePaginatedVisitedPlaces(visitedPlacesObj),
  };
}
