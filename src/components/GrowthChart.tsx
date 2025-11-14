import { GrowthRecord, Baby } from '@/lib/types';
import { calculateWeightPercentile } from '@/lib/whoPercentiles';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { differenceInDays } from 'date-fns';

interface GrowthChartProps {
  baby: Baby;
  records: GrowthRecord[];
  metric: 'weight' | 'length' | 'head_circumference';
}

export function GrowthChart({ baby, records, metric }: GrowthChartProps) {
  const chartData = records
    .filter(r => r[metric])
    .map(record => {
      const ageInDays = differenceInDays(new Date(record.recorded_at), new Date(baby.date_of_birth));
      return {
        age: ageInDays,
        value: record[metric],
        date: new Date(record.recorded_at).toLocaleDateString(),
      };
    })
    .sort((a, b) => a.age - b.age);

  const getAxisLabel = () => {
    switch (metric) {
      case 'weight':
        return 'Weight (kg)';
      case 'length':
        return 'Length (cm)';
      case 'head_circumference':
        return 'Head Circumference (cm)';
    }
  };

  const getChartColor = () => {
    switch (metric) {
      case 'weight':
        return '#0F766E';
      case 'length':
        return '#7C3AED';
      case 'head_circumference':
        return '#DC2626';
    }
  };

  if (chartData.length === 0) {
    return (
      <div className="flex items-center justify-center h-64 text-muted-foreground">
        No data yet. Add measurements to see growth trends.
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={chartData}>
        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
        <XAxis 
          dataKey="age" 
          label={{ value: 'Age (days)', position: 'insideBottom', offset: -5 }}
          className="text-xs"
        />
        <YAxis 
          label={{ value: getAxisLabel(), angle: -90, position: 'insideLeft' }}
          className="text-xs"
        />
        <Tooltip 
          content={({ active, payload }) => {
            if (active && payload && payload.length) {
              return (
                <div className="bg-background border rounded-lg p-2 shadow-lg">
                  <p className="text-sm font-medium">{payload[0].payload.date}</p>
                  <p className="text-sm text-muted-foreground">
                    Age: {payload[0].payload.age} days
                  </p>
                  <p className="text-sm font-semibold" style={{ color: getChartColor() }}>
                    {getAxisLabel()}: {payload[0].value}
                  </p>
                </div>
              );
            }
            return null;
          }}
        />
        <Legend />
        <Line 
          type="monotone" 
          dataKey="value" 
          stroke={getChartColor()}
          strokeWidth={3}
          dot={{ r: 5, fill: getChartColor() }}
          name={baby.name}
          activeDot={{ r: 7 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
