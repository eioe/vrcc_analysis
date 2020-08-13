position_to_numeric = function(position_vector) {
  
  # Inputs:
  # - position_vector <vector>        : a vector of strings in form "(0.9090, 1.0909, 2.09089)"
  
  # Outputs:
  # - numeric_pos <list> of <numeric> : a list of numeric 2D vectors
  
  numeric_pos = list()
  
  for (i in seq_along(position_vector)) {
    pos = gsub('\\(|\\)', '', position_vector[i])
    pos = unlist(strsplit(pos, ","))
    pos = as.numeric(pos[c(1, 3)])
    numeric_pos[[i]] = pos
  }
  numeric_pos
}


get_euclidean_dist = function(pos_1, pos_2) {
  sqrt(sum((pos_1 - pos_2)**2))
}


get_angle <- function(pos_1, pos_2){
  dot_prod <- pos_1 %*% pos_2
  norm_1 <- norm(pos_1, type="2")
  norm_2 <- norm(pos_2, type="2")
  theta <- acos(dot_prod / (norm_1 * norm_2))
  as.numeric(theta)
}


compute_euclidean_distances = function(list_1, list_2) {
  
  # Computes euclidean distances between two lists of coordinates in form e.g. "(0.67, 0.0, 0.786)", 
  # using `position_to_numeric()` to parse theses coordinates to a valid format, e.g. (0.67, 0.786)
  
  if (length(list_1) != length(list_2)) {
    stop('\nLenghts of provided lists are not equal.')
  }
  
  numeric_1 = position_to_numeric(list_1)
  numeric_2 = position_to_numeric(list_2)
  
  distances = c()
  
  cat('\nComputing euclidean distances for', length(numeric_1), 'observations...\n')
  
  for (i in 1:length(numeric_1)) {
    distances[i] = get_euclidean_dist(numeric_1[[i]], numeric_2[[i]])
  }
  
  cat('\nDistances computed.\n')
  
  distances

}


compute_angles = function(list_1, list_2) {
  
  # Computes angle in radians between two lists of coordinates in form e.g. "(0.67, 0.0, 0.786)", 
  # using `position_to_numeric()` to parse theses coordinates to a valid format, e.g. (0.67, 0.786)
  
  if (length(list_1) != length(list_2)) {
    stop('\nLenghts of provided lists are not equal.')
  }
  
  numeric_1 = position_to_numeric(list_1)
  numeric_2 = position_to_numeric(list_2)
  
  distances = c()
  
  cat('\nComputing angles for', length(numeric_1), 'observations...\n')
  
  for (i in 1:length(numeric_1)) {
    distances[i] = get_angle(numeric_1[[i]], numeric_2[[i]])
  }
  
  cat('\nAngles computed.\n')
  
  distances
  
}
