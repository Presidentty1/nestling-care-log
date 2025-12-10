import { describe, it, expect } from 'vitest';
import { unitConversion } from '@/services/unitConversion';

describe('unitConversion', () => {
  describe('Volume conversions', () => {
    it('converts oz to ml correctly', () => {
      expect(unitConversion.ozToMl(1)).toBe(30);
      expect(unitConversion.ozToMl(4)).toBe(118);
      expect(unitConversion.ozToMl(8)).toBe(237);
      expect(unitConversion.ozToMl(0)).toBe(0);
    });

    it('converts ml to oz correctly', () => {
      expect(unitConversion.mlToOz(30)).toBeCloseTo(1, 1);
      expect(unitConversion.mlToOz(120)).toBeCloseTo(4.1, 1);
      expect(unitConversion.mlToOz(240)).toBeCloseTo(8.1, 1);
      expect(unitConversion.mlToOz(0)).toBe(0);
    });

    it('maintains precision on round trip conversion', () => {
      const original = 90;
      const converted = unitConversion.ozToMl(unitConversion.mlToOz(original));
      expect(converted).toBeCloseTo(original, 0);
    });
  });

  describe('Weight conversions', () => {
    it('converts lb to g correctly', () => {
      expect(unitConversion.lbToG(1)).toBe(454);
      expect(unitConversion.lbToG(7)).toBe(3175);
      expect(unitConversion.lbToG(0)).toBe(0);
    });

    it('converts g to lb correctly', () => {
      expect(unitConversion.gToLb(454)).toBeCloseTo(1, 2);
      expect(unitConversion.gToLb(3175)).toBeCloseTo(7, 1);
      expect(unitConversion.gToLb(0)).toBe(0);
    });

    it('converts oz to g correctly', () => {
      expect(unitConversion.ozToG(1)).toBe(28);
      expect(unitConversion.ozToG(16)).toBe(454);
    });

    it('converts g to oz correctly', () => {
      expect(unitConversion.gToOz(28)).toBeCloseTo(1, 1);
      expect(unitConversion.gToOz(454)).toBeCloseTo(16, 0);
    });
  });

  describe('Length conversions', () => {
    it('converts in to cm correctly', () => {
      expect(unitConversion.inToCm(1)).toBeCloseTo(2.5, 1);
      expect(unitConversion.inToCm(20)).toBeCloseTo(50.8, 1);
      expect(unitConversion.inToCm(0)).toBe(0);
    });

    it('converts cm to in correctly', () => {
      expect(unitConversion.cmToIn(2.5)).toBeCloseTo(1, 1);
      expect(unitConversion.cmToIn(50)).toBeCloseTo(19.7, 1);
      expect(unitConversion.cmToIn(0)).toBe(0);
    });
  });

  describe('Storage converters', () => {
    it('converts display volume to storage (metric)', () => {
      expect(unitConversion.toStorageVolume(120, 'ml')).toBe(120);
    });

    it('converts display volume to storage (imperial)', () => {
      expect(unitConversion.toStorageVolume(4, 'oz')).toBe(118);
    });

    it('converts storage volume to display (metric)', () => {
      expect(unitConversion.fromStorageVolume(120, 'ml')).toBe(120);
    });

    it('converts storage volume to display (imperial)', () => {
      const result = unitConversion.fromStorageVolume(120, 'oz');
      expect(result).toBeCloseTo(4.1, 1);
    });
  });

  describe('Format functions', () => {
    it('formats volume correctly', () => {
      expect(unitConversion.formatVolume(120, 'ml')).toBe('120ml');
      expect(unitConversion.formatVolume(4, 'oz')).toBe('4oz');
    });

    it('formats weight correctly', () => {
      expect(unitConversion.formatWeight(3500, 'g')).toBe('3500g');
      expect(unitConversion.formatWeight(7, 'lb')).toBe('7 lb');
      expect(unitConversion.formatWeight(8, 'oz')).toBe('8oz');
    });

    it('formats length correctly', () => {
      expect(unitConversion.formatLength(50, 'cm')).toBe('50cm');
      expect(unitConversion.formatLength(20, 'in')).toBe('20in');
    });
  });
});
