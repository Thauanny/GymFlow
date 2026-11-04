import 'relevance_ranker.dart';

/// Fora da web não há modelo no navegador: usa palavras-chave.
RelevanceRanker createSemanticRanker() => KeywordRanker();
