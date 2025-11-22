import type { GrowthRecord, Baby } from '@/lib/types';
import { calculateWeightPercentile, calculateLengthPercentile, getExpectedWeight } from '@/lib/whoPercentiles';
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

  // Generate WHO percentile curves if we have baby sex
  const percentileCurves = baby.sex && (baby.sex === 'male' || baby.sex === 'female') && metric === 'weight'
    ? generatePercentileCurves(baby.sex, Math.max(...chartData.map(d => d.age)))
    : null;

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
      <LineChart data={percentileCurves ? [...chartData, ...percentileCurves] : chartData}>
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
        
        {/* WHO Percentile Curves */}
        {percentileCurves && (
          <>
            <Line type="monotone" dataKey="p3" stroke="#e0e0e0" strokeWidth={1} dot={false} name="3rd %ile" strokeDasharray="3 3" />
            <Line type="monotone" dataKey="p50" stroke="#999999" strokeWidth={1} dot={false} name="50th %ile" strokeDasharray="3 3" />
            <Line type="monotone" dataKey="p97" stroke="#e0e0e0" strokeWidth={1} dot={false} name="97th %ile" strokeDasharray="3 3" />
          </>
        )}
        
        {/* Baby's actual measurements */}
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

// Helper function to generate WHO percentile curves
function generatePercentileCurves(sex: 'male' | 'female', maxAge: number) {
  const curves: any[] = [];
  const step = Math.max(30, Math.floor(maxAge / 10)); // Sample every 30 days or 10 points
  
  for (let age = 0; age <= maxAge; age += step) {
    curves.push({
      age,
      p3: getExpectedWeight(age, sex, 3),
      p50: getExpectedWeight(age, sex, 50),
      p97: getExpectedWeight(age, sex, 97),
    });
  }
  
  return curves;
}
